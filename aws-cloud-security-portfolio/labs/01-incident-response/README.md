# Lab 01 - EC2 Compromise Investigation

**Source:** [AWS Skill Builder — Security Engineer Advanced Learning Plan (includes labs)](https://skillbuilder.aws/learning-plan/NTDPRSFC3F/aws-security-engineer-advanced-learning-plan-includes-labs/VUD51DEB41)

**Frameworks referenced:** NIST, PCI-DSS

> Screenshots from this lab can be stored under [`../../assets/images/`](../../assets/images/) for your portfolio.

---

## Overview

This lab places you on an incident response team responding to a potential compromise of an Amazon EC2 application server. The scenario begins with an alert driven by **multiple failed SSH login attempts**. Your job is to follow a disciplined process: **preserve evidence**, **analyze whether a breach occurred**, **reduce attack surface**, and **automate repeatable response** so similar events are handled consistently.

You work as a security engineer at **AnyCompany**, investigating an application server while balancing forensic integrity, operational safety, and stakeholder communication.

---

## Objectives

By the end of this lab, you should be able to:

- Capture compromised instance **metadata** and **persistent disks**
- Create a **snapshot** of the compromised instance’s volumes
- **Isolate** the instance and protect against **accidental termination**
- Review **system and security-relevant logs** to validate a suspected breach
- **Harden** instance access (e.g., move from SSH to **AWS Systems Manager Session Manager**)
- Design and validate **automated incident response** for repeated indicators (e.g., SSH auth failures)

---

## AWS Services Used

| Category | Services |
| -------- | -------- |
| Compute & storage | **Amazon EC2**, **Amazon EBS** (snapshots), **Amazon S3** (IR/evidence bucket) |
| Detection & logging | **Amazon GuardDuty** (context in learning path), **AWS CloudTrail**, **Amazon CloudWatch Logs** |
| Operations & automation | **AWS Systems Manager** (Run Command, Session Manager), **AWS Lambda**, **Amazon EventBridge** |
| Identity | **IAM** (instance profiles / roles) |

---

## Step-by-Step Walkthrough

### Phase 1 — Preserve evidence and isolate the instance

1. **Capture metadata and disk-related artifacts**  
   Collect instance metadata and upload forensic-relevant data to a designated **S3** bucket (e.g., IR bucket) per lab instructions.

2. **Enable termination protection**  
   On the compromised instance, enable **termination protection** to prevent accidental destruction during investigation.

3. **Capture disks (and memory strategy)**  
   - Take an **EBS snapshot** of the compromised volume.  
   - For **memory capture**, the lab emphasizes using **third-party tools** (e.g., approaches compatible with **LiME** on Linux) while avoiding risky direct interactive shell work that could alter state.  
   - **AWS Systems Manager Run Command** is used to invoke the **SSM Agent** on the host so scripts can run **without** ad-hoc SSH sessions that might contaminate the forensic picture. After capture, another snapshot can include the memory dump artifacts on disk.

4. **Optional: Stand up a copy for analysis**  
   Deploy a **new instance from the captured snapshot** if you need an isolated environment for deeper examination.

5. **Tag, decommission, and isolate**  
   - Tag the instance (e.g., **`Status=Quarantined`**).  
   - **Remove the IAM instance profile** from the affected instance to limit lateral movement via credentials.  
   - Attach a **quarantine security group** to restrict network connectivity.

**Phase 1 completion checklist (from lab):**

- Captured compromised instance metadata  
- Enabled termination protection  
- Captured disks into a snapshot (and related image workflow as required)  
- Tagged, decommissioned, and isolated the instance  

---

### Phase 2 — Investigate using logs and indicators

Review host and supporting telemetry to confirm or refute compromise. Example findings documented in the lab:

| Indicator | Severity |
| --------- | -------- |
| New privileged user | **HIGH** |
| Password authentication enabled | **MEDIUM–HIGH** |
| SSH service restarts | **MEDIUM** |
| Internal brute-force activity | **HIGH** |
| CloudWatch agent creation | **Normal** (context-dependent) |

**Remediation direction (stakeholder recommendation):**

- **Disable and block SSH** on this server where policy allows.  
- Prefer **AWS Systems Manager Session Manager** for access: **no inbound SSH**, **IAM-controlled** access, and **auditable** via **CloudTrail**.

---

### Phase 3 — Mitigate the vulnerability (hardening)

1. **Attach SSM permissions to the instance profile**  
   Grant the instance an **IAM role** with permissions required for **SSM** (per lab policy). **Reboot** if needed so the agent picks up the new role capabilities.

2. **Remove inbound SSH from the security group**  
   Remove the SSH rule and transition off the **quarantine** security group when the instance is ready to return to a controlled, least-privilege posture (per lab steps).

3. **Validate via Session Manager**  
   Connect through **SSM Session Manager**, confirm remediation, and **remove the quarantine tag** when appropriate.

---

### Phase 4 — Automate incident response

End-to-end flow (as built in the lab):

1. **Simulated SSH failures** originate from a **jump server** toward an **app server**.  
2. The app server emits **SSH authentication failure** logs to a **CloudWatch Logs** log group.  
3. A **subscription filter** on the log group forwards matching events to a **Log Enrichment Lambda**.  
4. The enrichment function resolves the **internal IP** to an **instance ID** and sends a structured event to **Amazon EventBridge**.  
5. An **EventBridge rule** invokes an **Automation Lambda** that performs **runbook-style** actions.

**Automated actions validated on a second instance (`app-server-2`):**

- Capture metadata and upload to the **IR S3 bucket**  
- Enable **termination protection**  
- Create a **volume snapshot**  
- Apply **`Status: Quarantine`** (or equivalent) tag  
- **Detach/remove** the current **IAM role** from the instance  
- Replace the application security group with **Quarantine-SG**

**Validation:** Trigger failed SSH attempts from the jump server and confirm the workflow completes (metadata in S3, tags, and security group updates).

---

## Security Insights & Best Practices

- **Evidence first:** Snapshots, metadata export to S3, and termination protection reduce the risk of losing artifacts during a live investigation.  
- **Minimize live “hands on” compromise:** Prefer **SSM Run Command** over interactive SSH on a suspect host when you need controlled execution with less impact on volatile state.  
- **Isolate before you dig:** Quarantine **security groups**, **IAM profile removal**, and clear **tags** improve clarity for operations and downstream forensics.  
- **Reduce remote access risk:** **Session Manager** avoids opening **SSH** to the internet or broad CIDRs, ties access to **IAM**, and improves **auditability**.  
- **Automate the boring and critical parts:** **CloudWatch Logs → Lambda → EventBridge** patterns scale detection-to-response and reduce mean time to contain **MTTC** for repetitive abuse signals (e.g., brute force).  
- **Map to frameworks:** NIST incident handling phases (preparation, detection, analysis, containment, eradication, recovery) and PCI-DSS expectations around logging, access control, and timely response align well with this workflow.

---

## AWS Security Specialty Exam Relevance

This lab reinforces topics that commonly appear on the **AWS Certified Security — Specialty** exam, including:

- **Incident response** on AWS (containment, forensics-friendly procedures)  
- **Logging and monitoring** (CloudTrail, CloudWatch Logs, subscription filters)  
- **Infrastructure security** (security groups, EC2 hardening, least-privilege network paths)  
- **Identity and access** (IAM roles for EC2, Session Manager prerequisites)  
- **Automated security operations** (Lambda, EventBridge, guardrails vs. manual runbooks)

Use it to connect **book knowledge** to **ordered procedures**: what you lock first, what you preserve, and how you prove the story with logs.

---

## Personal Reflections

Working through a full **preserve → analyze → remediate → automate** loop made the tradeoffs concrete: snapshots and S3 uploads feel slow until you imagine explaining to leadership why evidence disappeared. The lab’s emphasis on **not** defaulting to SSH on a suspect box matched real IR discipline—**Run Command** and **Session Manager** are not just convenience features, they are **control and evidence** features.

Building the **CloudWatch → Lambda → EventBridge** pipeline was the most satisfying checkpoint: seeing **SSH failure noise** turn into **consistent containment actions** showed how security engineering scales. If I revisit this write-up, I would add **explicit runbook IDs**, **RTO/RPO assumptions**, and **a table mapping each automated action to a NIST phase** so the narrative reads equally well to technical and GRC audiences.
