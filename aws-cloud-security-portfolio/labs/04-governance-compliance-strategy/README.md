# Lab 04 - Automate infrastructure compliance with AWS Config

**AWS services:** AWS Config, AWS Systems Manager Automation (as used for remediation in the lab flow), Amazon EC2, Amazon S3, IAM

**Frameworks:** Governance, risk, and compliance (GRC) practices aligned with **continuous compliance** and **audit readiness**

Screenshots are stored in this repo under [`../../assets/images/lab04-aws-config-compliance/`](../../assets/images/lab04-aws-config-compliance/).

---

## Overview

As a **cloud security administrator** at **AnyCompany**, you must protect a growing inventory of **EC2** instances (application testing) and **S3** buckets (intellectual property). The organization needs to **discover resources**, **evaluate configuration** against policy, **detect drift**, and **remediate automatically** instead of relying on one-off manual fixes.

This lab walks through **AWS Config**: resource inventory, **managed rules**, **remediation actions**, and the **Config dashboard** for ongoing compliance visibility.

**How to read the walkthrough:** The screenshots follow a typical **Config** onboarding and **remediation** story: turn on **recording**, add **rules**, see **noncompliance**, attach **remediation**, execute **fix**, confirm **COMPLIANT**. Each block below maps **numbered images** to that story so the album reads as **evidence**, not a silent slideshow.

---

## Objectives

By the end of this lab, you will be able to:

- Apply **AWS Config managed rules** to selected resources
- Configure **automated remediation** triggered by **noncompliant** evaluations
- Use the **AWS Config dashboard** to monitor **resource compliance** over time

---

## AWS Services Used

| Area | Services |
| ---- | -------- |
| Compliance & inventory | **AWS Config** (recorders, rules, conformance packs as applicable) |
| Remediation | **AWS Systems Manager Automation** (or **Config**-managed remediation actions, per lab) |
| Resources in scope | **Amazon EC2**, **Amazon S3**, **IAM** identities referenced by rules |

---

## Step-by-Step Walkthrough

### Phase A — Enable AWS Config and the configuration recorder

**Goal:** **AWS Config** must **continuously record** configuration items for resource types you care about. Without a **recorder** in the correct **region** and **account**, rules have nothing to evaluate.

The following screenshots open the **Config** console, confirm **setup**, and show **recorder** / **delivery channel** style settings (exact labels vary slightly by console version).

![Walkthrough 01 — Get started / welcome](../../assets/images/lab04-aws-config-compliance/01.png)

**What you're seeing:** **Get started** or **Dashboard** entry—often **one-click setup** prompt or **service landing**. **Why:** Establishes that **Config** will run in **this Region** (rules are **regional**).

![Walkthrough 02 — Recorder or settings (1)](../../assets/images/lab04-aws-config-compliance/02.png)

**What you're seeing:** **Settings** related to **recording**—e.g., **record all resources** vs **specific types**, or **include global resources** (**IAM**) where the lab enables it. **Interview point:** **IAM** resources are **global**; recording them typically ties to **us-east-1** delivery—know your org’s **multi-region** strategy.

![Walkthrough 03 — Recorder or settings (2)](../../assets/images/lab04-aws-config-compliance/03.png)

**What you're seeing:** Continuation—**S3 bucket** for **Config** snapshots/logs or **role** selection for **Config** service-linked / service role. **Security:** The **role** should be **least privilege** for **s3:PutObject** to the **delivery bucket** only.

### Phase B — Confirm recording and explore the resource inventory

**Goal:** Validate that **configuration items** are arriving before you attach **rules**—otherwise **INSUFFICIENT_DATA** dominates and hides real misconfigurations.

![Walkthrough 04 — Recording on / dashboard](../../assets/images/lab04-aws-config-compliance/04.png)

**What you're seeing:** **Recorder** status **ON** and/or **last successful delivery** timestamp. **Verify:** No **access denied** to the **S3** delivery bucket in **CloudTrail**.

![Walkthrough 05 — Resources or timeline](../../assets/images/lab04-aws-config-compliance/05.png)

**What you're seeing:** **Resource inventory** browse or **timeline**—**EC2**, **S3**, **SecurityGroup**, etc. **Hunting use:** **Config** is also a **CMDB-lite** for security reviews.

![Walkthrough 06 — Resource detail](../../assets/images/lab04-aws-config-compliance/06.png)

**What you're seeing:** A **specific resource** **configuration item**—attributes the **managed rules** will later inspect (e.g., **public ACL**, **unencrypted volume**).

### Phase C — Add managed rules and scope resources

**Goal:** Attach **AWS Config managed rules** that match policy intent (e.g., **S3 bucket public read prohibited**, **encrypted volumes**, **required tags**). Scope **resource identifiers** or **tags** so blast radius of **remediation** is controlled.

![Walkthrough 07 — Add rule / rule library](../../assets/images/lab04-aws-config-compliance/07.png)

**What you're seeing:** **Add rule** or **Conformance packs** entry with **rule** search. **GRC tip:** Start with **high-severity**, **low-noise** rules; expand after **tuning**.

![Walkthrough 08 — Rule parameters](../../assets/images/lab04-aws-config-compliance/08.png)

**What you're seeing:** **Parameter** UI for the chosen rule—**optional** keys, **resource ID** filters, or **tag** filters. **Why parameters matter:** Same rule name with different **scope** changes **who** gets remediated.

![Walkthrough 09 — Rule saved / rule list](../../assets/images/lab04-aws-config-compliance/09.png)

**What you're seeing:** Rule appears in **Rules** list with **COMPLIANT** / **NON_COMPLIANT** / **NOT_APPLICABLE** / **INSUFFICIENT_DATA** pending first evaluation.

### Phase D — Observe noncompliance and evaluate results

**Goal:** Let **Config** run **periodic** or **configuration-change** triggers, then **drill into** **NON_COMPLIANT** resources—this is the **detective** outcome stakeholders see in audits.

![Walkthrough 10 — Compliance summary](../../assets/images/lab04-aws-config-compliance/10.png)

**What you're seeing:** **Compliance by rule** summary—counts of **noncompliant** resources. **Story:** “We **measure** posture continuously, not only at **quarterly** scans.”

![Walkthrough 11 — Noncompliant resource list](../../assets/images/lab04-aws-config-compliance/11.png)

**What you're seeing:** **Resources** failing a specific rule with **rule name** and **resource ID**. **Next:** Open **details** → **timeline** to see **what changed**.

![Walkthrough 12 — Rule evaluation detail](../../assets/images/lab04-aws-config-compliance/12.png)

**What you're seeing:** **Evaluation result** explanation—**expected** vs **actual** configuration fields. **Evidence pack:** Screenshot + **export** **configuration timeline** for auditors.

### Phase E — Configure automated remediation (SSM Automation)

**Goal:** Attach a **remediation action** so **NON_COMPLIANT** triggers an **SSM Automation runbook** (or **Config**-managed action) with a **controlled IAM role**—**corrective** control.

![Walkthrough 13 — Remediation configuration](../../assets/images/lab04-aws-config-compliance/13.png)

**What you're seeing:** **Remediation action** wizard—**target** rule, **SSM document** / **Automation** ARN, **parameters** mapping **resource ID** into the document input. **Safety:** Use **manual approval** or **canary** accounts first in real life.

![Walkthrough 14 — Remediation IAM / parameters](../../assets/images/lab04-aws-config-compliance/14.png)

**What you're seeing:** **IAM role** for **remediation** execution and **parameter** completion. **Least privilege:** Role should only **fix** the targeted resource class (e.g., **s3:PutBucketPublicAccessBlock**).

![Walkthrough 15 — Remediation saved](../../assets/images/lab04-aws-config-compliance/15.png)

**What you're seeing:** Remediation **associated** with rule—**automatic** vs **manual** trigger per lab. **Operational note:** **Rate limits** and **API errors** should surface in **SSM** execution logs.

### Phase F — Execute remediation and verify compliance

**Goal:** Trigger **remediation** (automatic on next evaluation or **manual** “Remediate” in console), watch **SSM Automation** **success**, then confirm **Config** moves resource to **COMPLIANT**.

![Walkthrough 16 — Trigger remediation / execution](../../assets/images/lab04-aws-config-compliance/16.png)

**What you're seeing:** **Remediate** button workflow or **automation** **start**—**execution ID** visible. **Troubleshooting:** If **FAILED**, open **Automation** → **Steps** → **CloudWatch Logs** for the document.

![Walkthrough 17 — Execution success / Config re-eval](../../assets/images/lab04-aws-config-compliance/17.png)

**What you're seeing:** **Successful** automation steps and/or **Config** **re-evaluation** in progress. **Time lag:** **Config** may take **minutes** to refresh **compliance** after API changes.

![Walkthrough 18 — Dashboard — compliant](../../assets/images/lab04-aws-config-compliance/18.png)

**What you're seeing:** **Dashboard** or **rule** detail showing **COMPLIANT** state—**closure** of the **detect → remediate → verify** loop. **Executive summary:** “Drift was **found** and **fixed** with **audit trail**.”

---

## Security Insights & Best Practices

- **Detective + corrective controls:** **Config rules** provide **continuous evaluation**; pairing them with **automated remediation** shortens **exposure window** for misconfigurations.
- **Scope deliberately:** target **high-risk** resource types (e.g., **public S3**, **open security groups**, **unencrypted volumes**) before broadening rule coverage.
- **Evidence for auditors:** **Config timeline** and **rule history** support **prove-it** conversations for **SOC**, **ISO**, and **PCI** style programs—when paired with **change management** and **least privilege** on who can edit rules and remediations.

---

## AWS Security Specialty Exam Relevance

**AWS Config** appears frequently across **governance**, **logging/monitoring**, and **data protection** domains on the **AWS Certified Security — Specialty** exam—especially **rule evaluation**, **remediation**, and **integration** with other services.

---

## Personal Reflections

**Config** is most valuable when treated as a **product**, not a checkbox: pick **fewer, sharper** rules, wire **remediation** with **safe defaults**, and review **false positives** as a team ritual. The lab’s screenshot trail is a good base for a **runbook** that names **which rule**, **which remediation document**, and **who approves** exceptions.
