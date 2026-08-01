# Lab 05 - Event-driven order-processing microservices

**Status:** 🚧 **In progress** — the application core is built and running locally; the platform layer (containerization, CI/CD, GitOps, IaC, observability) is the active work stream.

**Stack:** **FastAPI**, **PostgreSQL**, **Redis**, **RabbitMQ**, **Docker**, **12-factor** configuration

**Domains:** Software architecture · Distributed systems · Platform engineering · Reliability

> **Note on scope:** This is a **written architecture and operations write-up**. The application source for `order-system` is a **private project** and is **not published** as part of this portfolio — what follows are the design decisions, trade-offs, and the operational plan, which is the part worth reviewing.

---

## Overview

`order-system` is an **event-driven order-processing platform** built as five independently-owned services. It exists to work through a specific engineering question honestly: **where does a distributed system need strong consistency, and where is it actively harmful?**

The short answer this system commits to — and the thread running through every section below — is:

> **The synchronous core fails fast. The asynchronous edge absorbs.**

Anything required to decide whether an order is **valid** happens synchronously and is allowed to reject the request. Anything that merely **reacts** to a valid order happens asynchronously and is never allowed to make the order fail.

---

## The five services

| Service | Owns | Consistency posture |
| ------- | ---- | ------------------- |
| **users** | Customer identity and account state | **Synchronous** — queried during order placement |
| **catalog** | Products, availability, and the **authoritative price** | **Synchronous** — queried during order placement |
| **orders** | Order lifecycle; acts as the **orchestrator** | **Synchronous** core; **publishes** events |
| **payments** | Payment intent and settlement state | **Asynchronous** — reacts to order events |
| **notifications** | Customer-facing messaging | **Asynchronous** — reacts to order events |

### Database-per-service

Each service owns a **private PostgreSQL database**. No service reads another service's tables — not for reporting, not for convenience, not "just this once."

This is the constraint that makes everything else in this write-up necessary. It costs real ergonomics: there are no cross-service joins, and answering "show me this customer's orders with product names" requires composition at the service layer rather than a single query. That cost is accepted deliberately, because a **shared database is a shared deployment**: it silently couples release cadence, schema migrations, and failure domains across teams that are nominally independent. Paying the query cost buys the ability to deploy `catalog` on a Tuesday without a `payments` regression review.

**Redis** sits alongside as a caching and ephemeral-state layer, not as a system of record.

---

## Architecture notes

### Orders as a synchronous orchestrator

`orders` is deliberately **not** a thin CRUD service. When an order is placed, it acts as an **orchestrator** and calls **users** and **catalog** synchronously, in-request:

1. **users** — does this customer exist and is the account in a state permitted to order?
2. **catalog** — do these products exist, are they available, and **what do they actually cost?**

Both answers are required *before* an order row is written. There is no "accept now, validate later" path for these two checks, because both can produce an order that should never have existed — an order against a deleted account, or an order at a price the business never offered.

I chose **orchestration over choreography** here for a reason that is about operations more than purity: with orchestration, the order-placement flow has **one owner and one place to read**. `orders` describes the entire happy path in a single service. In a fully choreographed design, that same flow is an emergent property of five event handlers, and reconstructing "why did this order end up in this state?" becomes an exercise in log archaeology across five services. For a flow this business-critical, **legibility beats decoupling**.

### Server-side pricing, and money as integer cents

Two decisions that look small and are not.

**Pricing is resolved server-side.** The client submits *what* it wants — product identifiers and quantities. It does **not** submit prices. `orders` asks `catalog` for the authoritative price and computes the total itself.

A client-supplied price is not a convenience feature, it is an **unauthenticated write to your revenue**. Any client-side total is advisory at best and attacker-controlled at worst; treating the catalog as the single source of pricing truth removes an entire class of tampering rather than trying to validate it after the fact. The visible total in a UI is a *rendering* of price, never the *source* of it.

**Money is stored and transported as integer cents.** Never floating point.

Binary floating point cannot represent most decimal fractions exactly. The failure mode is not theoretical — it is a total that renders as `19.99` and sums to `19.989999999999998`, reconciliation reports that disagree with the ledger by amounts too small to notice and too persistent to ignore, and rounding drift that compounds silently across line items. Integers make the arithmetic exact and the bugs impossible rather than rare. Formatting to a currency string is a **presentation concern**, handled at the edge, once.

### Publishing `OrderCreated` to RabbitMQ

Once the order is validated and durably written, `orders` publishes an **`OrderCreated`** event to **RabbitMQ**. Downstream services subscribe:

- **payments** picks up the event to begin settlement.
- **notifications** picks up the event to inform the customer.

Critically, **`orders` does not know or care who is listening.** It does not call `payments`. It does not call `notifications`. It announces a fact — *this order exists* — and returns to the client.

This is where the decoupling actually pays for itself. Adding a sixth consumer later — analytics, fraud scoring, a warehouse integration — requires **no change to `orders`**. New subscribers attach to the event stream; the publisher is untouched. That property is the entire argument for the message broker, and it only holds if the publisher is never permitted to learn its consumers' names.

### The consistency boundary

```
     ── SYNCHRONOUS CORE ──────────────►│◄───── ASYNCHRONOUS EDGE ─────
                                        │
   client ──► orders ──► users          │   OrderCreated ──► payments
                    └──► catalog        │                └──► notifications
                                        │
   fails fast · rejects the request     │   absorbs · retries · never rejects
```

The vertical line is the most important design artifact in the system. **Left of it, failure is loud and immediate. Right of it, failure is patient.**

If `notifications` is down, the customer still has an order — they just get their email late. That is a **degraded experience**. If the same failure were synchronous, it would be a **lost sale**, because an unsendable confirmation email would have failed the order. Putting notifications on the async side converts a revenue incident into a latency incident.

---

## Reliability lens

### 503 when a dependency is down

When `users` or `catalog` is unavailable, `orders` returns **`503 Service Unavailable`**. It does **not** return `500`, and it does **not** guess.

This distinction is doing real work:

- **`500`** says *I am broken.* It signals a defect, points on-call at the wrong service, and tells the client that retrying is pointless.
- **`503`** says *I am healthy, my dependency is not, and this is worth retrying.* It is semantically **retryable**, it pairs correctly with `Retry-After`, and it lets load balancers and clients back off intelligently instead of hammering a struggling dependency.

The alternative — degrading gracefully by accepting the order and validating later — was rejected for the synchronous core. An order accepted without a verified price or a verified account is not a **degraded** order, it is a **potentially invalid** one, and cleaning up invalid orders after the fact is materially harder than asking the client to try again in ten seconds. **Refusing to answer is safer than answering wrongly.**

### The dual-write problem — the honest weakness

This is the sharpest unresolved trade-off in the system, and it is documented here rather than hidden.

Order placement performs **two writes to two systems**: the order row goes to **PostgreSQL**, and the `OrderCreated` event goes to **RabbitMQ**. These are separate systems with **no shared transaction**. There is a window between them.

The failure mode is narrow and real:

| Failure point | Result |
| ------------- | ------ |
| DB commit succeeds, broker publish fails | Order exists; **no event**. Payment never initiated, customer never notified. A **silently orphaned order**. |
| Broker publish succeeds, DB commit rolls back | Event exists; **no order**. Downstream services act on an order that does not exist. |

Reordering the two writes does not fix this — it only chooses which of the two failures you prefer. **There is no ordering that makes a dual write atomic.**

**The known fix: the transactional outbox pattern.** Instead of publishing to the broker directly, the event is written to an **`outbox` table in the same PostgreSQL transaction as the order itself**. One transaction, one database, genuinely atomic — the order and the intent-to-publish either both commit or both roll back. A **separate relay process** then reads unpublished outbox rows and pushes them to RabbitMQ, marking them published on success.

This converts the guarantee from "**maybe delivered**" to "**at-least-once delivered**." The relay may publish a row twice if it crashes between publishing and marking — which is precisely why consumers must be **idempotent**, keyed on event identity. That is a tractable, well-understood requirement. A silently lost order is not.

**Current state:** the outbox is **specified and not yet implemented**. The system today has a real dual-write window. Naming that honestly is more useful than a write-up that implies a robustness the code does not have.

---

## DevOps playbook

This is the **active work stream**, and the reason the lab is marked in progress.

### Already in place

**12-factor configuration.** All configuration — database URLs, broker credentials, service endpoints — arrives through the **environment**, never through committed config files. Secrets are never in the image and never in version control. This is the prerequisite for everything below: an artifact that cannot be promoted across environments without rebuilding is not a deployable artifact.

**Docker.** Each service builds to its own image. The **build artifact is identical across environments**; only the injected environment differs.

**Service independence.** Database-per-service and event-driven edges mean services are independently deployable *in principle*. The remaining work is making that true *in practice*.

### Roadmap

| Phase | Work | Objective |
| ----- | ---- | --------- |
| **1 — Containerization** | Multi-stage builds, non-root runtime users, pinned base images, slim final layers, meaningful health endpoints | Small, reproducible, non-privileged images that an orchestrator can actually schedule and probe |
| **2 — CI/CD** | Per-service pipelines: lint → test → build → scan → publish. Image scanning and dependency audit as **blocking** gates | No artifact reaches a registry without passing the same gates every time |
| **3 — GitOps** | Declarative desired state in Git; a reconciler converges the cluster. Deploys become **pull requests** | Git is the single source of truth for what is running. Rollback is `git revert`, and the audit trail is the commit history |
| **4 — IaC** | Infrastructure declared and version-controlled; environments rebuildable from source | No hand-clicked infrastructure. Environment parity becomes verifiable rather than assumed |
| **5 — Observability** | Structured logging, **correlation IDs propagated across the sync core and into published events**, metrics, distributed tracing | The ability to answer "what happened to *this* order?" as one query instead of five log searches |

**Phase 5 is the one that matters most for this architecture specifically.** An event-driven system without correlated traces is genuinely difficult to debug — an order's lifecycle spans an HTTP request, two synchronous dependency calls, a broker hop, and two independent consumers. Without a correlation ID threaded through the `OrderCreated` payload, reconstructing that path is manual. **The observability work is not a finishing touch here; it is what makes the asynchronous design operable.**

---

## Personal reflections

The most useful thing this project taught me is that **"microservices" is not the interesting decision** — the interesting decision is **where you draw the consistency boundary**, and that boundary should be drawn by asking *what must be true for this operation to be valid*, not by asking *what would be architecturally elegant*.

Validation of identity and price must be true, so those calls are synchronous and allowed to fail the request. Notification and settlement merely react, so they live behind a broker and are allowed to be late. Getting that line in the right place is worth more than any amount of framework choice.

The second lesson is about **documenting weaknesses**. The dual-write window is a real flaw in the current implementation. It would have been easy to write this document without mentioning it. But an architecture write-up that only lists strengths is marketing, not engineering — and in a review, the ability to name your system's sharpest unresolved trade-off and the specific pattern that resolves it is a far better signal than a clean diagram.
