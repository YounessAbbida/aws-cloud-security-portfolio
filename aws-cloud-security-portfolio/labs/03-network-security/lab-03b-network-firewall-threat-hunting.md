# Lab 03B - Threat hunting with AWS Network Firewall

**AWS services:** AWS Network Firewall, Amazon Route 53 Resolver DNS Firewall, AWS Transit Gateway (lab architecture), Amazon CloudWatch Logs, **CloudWatch Logs Insights**, **Contributor Insights**, Amazon EC2, Amazon VPC

**Screenshots:** [`../../assets/images/lab03b-network-firewall-threat-hunting/`](../../assets/images/lab03b-network-firewall-threat-hunting/)

---

## Overview

As **AnyCompany’s** first network security engineer, you address **weak visibility** into egress traffic and suspected **compromised EC2** instances. You implement **AWS Network Firewall** for **stateful inspection** (including **Suricata-compatible** rules) and **Route 53 Resolver DNS Firewall** for **DNS-layer** enforcement and visibility. Together they support **egress filtering**, **DNS monitoring**, and **threat hunting** to find **rogue instances**.

## Objectives

By the end of this lab, you should be able to:

- Configure **stateful rule groups** in **Network Firewall** using **Suricata-compatible IPS** syntax
- Build **DNS Firewall** rules using **managed** and **custom** domain lists to **alert** or **block** suspicious queries
- Use **Logs Insights** and **Contributor Insights** to identify **noisy or compromised** EC2 instances from **DNS** and **firewall** logs

## AWS Services Used

| Area | Services |
| ---- | -------- |
| Firewall & DNS | **AWS Network Firewall**, **Route 53 Resolver DNS Firewall** |
| Network fabric | **Amazon VPC**, **Transit Gateway**, **firewall endpoints** |
| Observability | **CloudWatch Logs**, **Logs Insights**, **Contributor Insights** |
| Compute | **Amazon EC2** |

## Step-by-Step Walkthrough

### Architecture and theory

Traffic path (conceptual): **EC2** → **DNS Firewall** (query inspection) → **Network Firewall** (stateful inspection, Suricata, domain lists) → **Internet Gateway**.

**DNS Firewall** and **Network Firewall** are **complementary**: DNS Firewall catches **malicious resolution** early; Network Firewall handles **IPs**, **ports**, and **non-DNS** abuse. **Cost note:** Network Firewall bills per **endpoint per AZ** and **per GB processed**—multi-AZ designs multiply fixed cost.

**Why DNS Firewall matters:** non-HTTP protocols, **raw TCP** to resolved IPs, **DNS tunneling**, and **managed threat intel lists** at the DNS layer.

### Task 1 — Explore the network architecture

![Architecture exploration (1)](../../assets/images/lab03b-network-firewall-threat-hunting/01.png)

![Architecture exploration (2)](../../assets/images/lab03b-network-firewall-threat-hunting/02.png)

![Architecture exploration (3)](../../assets/images/lab03b-network-firewall-threat-hunting/03.png)

![Architecture — Task 1 detail](../../assets/images/lab03b-network-firewall-threat-hunting/04.png)

![Architecture — inspection path](../../assets/images/lab03b-network-firewall-threat-hunting/05.png)

**Consider:** The **VPC endpoints** in the inspection path are **firewall endpoints**. They connect the **Inspection-Egress-VPC** to **Network Firewall**, letting **Transit Gateway** traffic be **inspected** before **NAT Gateway** egress.

### Task 2 — Stateful firewall rules

Firewall **VPC attachment**, subnets, and endpoints:

![Firewall VPC and subnets (1)](../../assets/images/lab03b-network-firewall-threat-hunting/06.png)

![Firewall VPC and subnets (2)](../../assets/images/lab03b-network-firewall-threat-hunting/07.png)

![Firewall VPC and subnets (3)](../../assets/images/lab03b-network-firewall-threat-hunting/08.png)

![Firewall VPC and subnets (4)](../../assets/images/lab03b-network-firewall-threat-hunting/09.png)

#### Task 2.2 — Suricata IPS example

Example rule:

`alert tcp any any <> any 443 (msg:"SURICATA Port 443 but not TLS"; flow:to_server,established; app-layer-protocol:!tls; sid:2271003; rev:1;)`

![Suricata rule in console](../../assets/images/lab03b-network-firewall-threat-hunting/10.png)

**Rule breakdown:** **TCP/443** traffic where the application layer is **not TLS** on an **established** flow to the server—useful for spotting **cleartext** or **misuse** of **443/tcp**.

#### Attach the rule group to the firewall

![Attach stateful rule group](../../assets/images/lab03b-network-firewall-threat-hunting/11.png)

#### Task 2.3 — Managed rule groups

![Managed rule groups](../../assets/images/lab03b-network-firewall-threat-hunting/12.png)

### Task 3 — Route 53 Resolver DNS Firewall

HTTP/HTTPS domain lists alone do not stop **other protocols** to the same names. **DNS Firewall** blocks **resolution** of suspect domains from VPC workloads.

![DNS Firewall — rule configuration (1)](../../assets/images/lab03b-network-firewall-threat-hunting/13.png)

![DNS Firewall — rule configuration (2)](../../assets/images/lab03b-network-firewall-threat-hunting/14.png)

**Second rule** and additional DNS policy screens:

![DNS Firewall — second rule](../../assets/images/lab03b-network-firewall-threat-hunting/15.png)

![DNS Firewall — policy screens](../../assets/images/lab03b-network-firewall-threat-hunting/16.png)

![DNS Firewall — policy screens (2)](../../assets/images/lab03b-network-firewall-threat-hunting/17.png)

**Send DNS query logs to CloudWatch:**

![DNS query logging to CloudWatch](../../assets/images/lab03b-network-firewall-threat-hunting/18.png)

### Task 4 — Threat hunting

**Contributor Insights** / **Logs Insights** on **Route 53 Resolver** logs:

![Threat hunting — Resolver logs (1)](../../assets/images/lab03b-network-firewall-threat-hunting/19.png)

![Threat hunting — Resolver logs (2)](../../assets/images/lab03b-network-firewall-threat-hunting/20.png)

![Threat hunting — Resolver logs (3)](../../assets/images/lab03b-network-firewall-threat-hunting/21.png)

![Threat hunting — Resolver logs (4)](../../assets/images/lab03b-network-firewall-threat-hunting/22.png)

**Compromised instance** indicators:

![Compromised instance](../../assets/images/lab03b-network-firewall-threat-hunting/23.png)

**Network Firewall** — **Logs Insights**:

![Network Firewall — Logs Insights (1)](../../assets/images/lab03b-network-firewall-threat-hunting/24.png)

![Network Firewall — Logs Insights (2)](../../assets/images/lab03b-network-firewall-threat-hunting/25.png)

![Network Firewall — Logs Insights (3)](../../assets/images/lab03b-network-firewall-threat-hunting/26.png)

**Alert example:** log indicates **FTP on port 443** (unexpected application on **443/tcp**):

![FTP on 443 alert example](../../assets/images/lab03b-network-firewall-threat-hunting/27.png)

### Task 5 — DNS exfiltration (encoding)

Encoded **base64** payload and decode step:

![Base64 encoded data](../../assets/images/lab03b-network-firewall-threat-hunting/28.png)

![Decode exfiltration payload](../../assets/images/lab03b-network-firewall-threat-hunting/29.png)

### Task 6 — Quarantine

Move compromised instances to a **quarantine security group**:

![Quarantine security group](../../assets/images/lab03b-network-firewall-threat-hunting/30.png)

## Security Insights & Best Practices

- **Layer DNS and packet inspection**; neither replaces the other.
- **Suricata** rules express **behavior** (e.g., “443 but not TLS”) that pure **port ACLs** miss.
- **Centralized logging** to **CloudWatch** enables **correlation** and **entity-centric** hunting (**Contributor Insights**).
- **Quarantine SGs** are a simple, auditable **containment** lever after **hunting** confirms suspicion.

## AWS Security Specialty Exam Relevance

Strong alignment with **AWS Network Firewall**, **DNS Firewall**, **logging/monitoring**, and **VPC egress** control patterns.

## Personal Reflections

The lab makes **DNS vs Network Firewall** responsibilities obvious in hindsight but easy to blur under time pressure. **Writing one paragraph** of “what each control sees” next to the architecture diagram is worth keeping for interviews and incident reviews.
