# Lab 01 - EC2 Compromise Investigation

**AWS services:** EC2, GuardDuty, CloudTrail (plus S3, EBS, CloudWatch Logs, Systems Manager, Lambda, EventBridge, IAM as used in the walkthrough)

**Frameworks:** NIST, PCI-DSS

Screenshots for this lab are stored in this repo under [`../../assets/images/lab01-ec2-compromise/`](../../assets/images/lab01-ec2-compromise/).

---

## Overview

In this lab, you act as a member of the incident response team after an alert about a possible **compromised EC2 instance**. You respond using processes and techniques for **investigation**, **analysis**, and **lessons learned**.

As a security engineer at **AnyCompany**, you are alerted to a potential breach on an application server where **multiple failed login attempts** were detected. You must **safely analyze** the instance to determine whether a breach occurred, **address vulnerabilities** that contributed to it, and perform **remediation**.

The walkthrough below follows a practical **contain → preserve → analyze → remediate → automate** sequence. Each screenshot is paired with a short explanation so readers (including hiring managers) can follow **intent** and **outcome**, not only the UI state.

### Lab context (screenshots)

The following slides establish the fictional scenario and learning goals for the exercise.

![Lab context — overview](../../assets/images/lab01-ec2-compromise/01-overview-01.png)

**What this shows:** The lab frames you as incident response staff responding to suspicious activity on an EC2-backed application server. It sets expectations around **safe** handling of a potentially compromised host (preserve evidence before deep changes, avoid destructive actions until containment is understood).

![Lab context — scenario](../../assets/images/lab01-ec2-compromise/02-overview-02.png)

**What this shows:** The scenario ties the work to **failed SSH login attempts** and the need to determine whether a real compromise occurred, harden the instance, and later **automate** similar responses—mirroring how organizations scale IR beyond one-off console work.

---

## Objectives

By the end of this lab, you should be able to:

- Capture compromised instance **metadata** and **persistent disks**
- Create a **snapshot** of the compromised instance
- **Isolate** the instance and protect against **accidental termination**
- Review **system logs** to validate the suspected breach
- **Update instance settings** to mitigate a vulnerability
- Create **automated incident response** for similar incidents in the future

---

## AWS Services Used

| Area | Services |
| ---- | -------- |
| Compute & storage | **Amazon EC2**, **Amazon EBS** (snapshots), **Amazon S3** (IR / evidence bucket) |
| Detection & audit | **Amazon GuardDuty**, **AWS CloudTrail** |
| Logging | **Amazon CloudWatch Logs** |
| Operations | **AWS Systems Manager** (Run Command, Session Manager) |
| Automation | **AWS Lambda**, **Amazon EventBridge** |
| Access | **IAM** (instance profiles / roles), **security groups** |

---

## Step-by-Step Walkthrough

**How to read this section:** Under each task, text before a screenshot explains **what you are doing and why**. After key screenshots, notes describe **what a reviewer should take away** from the evidence step—useful when presenting this lab in an interview.

### Task 1 — Capture compromised disks and metadata

**Goal:** Before changing network access or software on a suspect instance, **preserve volatile and persistent state** so analysis and legal/compliance stakeholders can trust the timeline. This task collects **instance metadata** and **disk-related artifacts**, stores copies in a dedicated **S3 IR bucket**, and begins **containment** (protection from accidental delete, snapshots, tagging, stripping risky access).

#### Task 1.1–1.2: Capture persistent disk / metadata and upload to S3

You export or collect data that identifies the instance configuration and supports disk-level forensics (for example, volume layout, attachment details, and environment facts the lab script or console workflow provides). That material is uploaded to a **central IR bucket** so it is **durable**, **versionable**, and **separate** from the compromised volume itself.

![Metadata and disk capture — EC2 / console](../../assets/images/lab01-ec2-compromise/03-task1-metadata.png)

**What you're seeing:** Console work tied to **capturing instance/volume metadata** (or running the lab’s capture flow). **Why it matters:** Metadata proves *what* was attached and *how* the instance was configured at response time—critical when snapshots are analyzed later or when writing the incident timeline.

The next steps upload that forensic package into the **IR S3 bucket** configured for the lab.

![Upload evidence to S3 (1)](../../assets/images/lab01-ec2-compromise/04-task1-s3-upload-01.png)

![Upload evidence to S3 (2)](../../assets/images/lab01-ec2-compromise/05-task1-s3-upload-02.png)

**What you're seeing:** Objects landing in (or being confirmed inside) the **IR bucket**—often with predictable prefixes or names from the lab automation. **Why it matters:** **S3** gives **WORM-friendly** retention options, bucket policies, and access logging; for recruiters, this demonstrates understanding that **evidence should leave the instance** early.

#### Task 1.3: Enable termination protection

**Termination protection** blocks API-driven termination of the instance. During IR, mistaken teardown is a common failure mode; this control buys time while snapshots and access reviews complete.

![Termination protection enabled](../../assets/images/lab01-ec2-compromise/06-task1-3-termination-protection.png)

**What you're seeing:** The instance attribute **DisableApiTermination** (termination protection) set to **enabled**. **Verify:** Attempting terminate should be rejected until protection is removed through a deliberate change.

#### Task 1.4: Capture instance memory and disks

**EBS snapshot** creates a **point-in-time, block-level copy** of the compromised volume. Analysts can attach a snapshot to a **clean** forensic instance without powering the original host back into a risky network posture.

![EBS snapshot of compromised volume](../../assets/images/lab01-ec2-compromise/07-task1-4-ebs-snapshot.png)

**What you're seeing:** Snapshot creation (or confirmation) for the volume backing the compromised instance. **Why it matters:** Snapshots are the standard AWS pattern for **immutable disk evidence** and for cloning disks into an isolated analysis VPC.

For **memory**, the lab uses **third-party tools** on the instance (e.g., approaches involving **LiME** on Linux). After capture, you can take **another snapshot** that includes the memory dump on disk.

**Forensic note:** You normally avoid ad-hoc **interactive SSH** on a suspect host because it can **change state** and affect forensics. **AWS Systems Manager Run Command** invokes the **SSM Agent** to run scripts remotely—reducing direct interactive access while still executing capture tooling.

#### Task 1.5 (optional): Restore for isolated analysis

Optional: launch a **new EC2 instance** from the snapshot (or an AMI derived from it) inside a **restricted** security context so malware analysts can work without touching production networking.

![Optional: instance from snapshot / AMI workflow](../../assets/images/lab01-ec2-compromise/08-task1-5-optional-restore.png)

**What you're seeing:** A recovery/analysis path from **snapshot → volume → instance**. **Interview angle:** Shows you know **analysis** can be **out-of-band** from the original incident VPC.

#### Task 1.6: Tag, decommission, and isolate

**Tagging** makes the instance visible in cost, CMDB, and automation filters. **`Status=Quarantined`** (or equivalent) signals to operators and Lambdas that this asset is under IR.

- Tag the instance (e.g., **`Status=Quarantined`**).

![Quarantine tag on instance](../../assets/images/lab01-ec2-compromise/09-task1-6-quarantine-tag.png)

**What you're seeing:** Instance tags reflecting **quarantine** state. **Why:** Tags often drive **EventBridge** rules, **Config** exemptions, or human runbooks.

**Removing the IAM instance profile** reduces the risk that **compromised credentials on the box** (or an attacker) use **instance role credentials** to call AWS APIs laterally.

- **Remove** the **IAM instance profile** from the instance.

![Remove IAM instance profile](../../assets/images/lab01-ec2-compromise/10-task1-6-remove-iam-role.png)

**What you're seeing:** The instance **no longer** has the production/application role attached. **Caveat:** Only do this after capture steps that still needed the role are complete.

**Quarantine security group** typically allows **no** (or minimal) inbound from application networks and may allow **egress** only to patching/logging endpoints—exact rules depend on lab policy.

- Move the instance to a **quarantine security group**.

![Quarantine security group applied](../../assets/images/lab01-ec2-compromise/11-task1-6-quarantine-sg.png)

**What you're seeing:** Primary ENI associated with **Quarantine-SG** (or similar). **Outcome:** **Network-layer containment** complements **IAM** and **tag** containment.

**Task 1 complete — checklist:**

- Captured compromised instance metadata  
- Enabled termination protection  
- Captured disks to snapshot (and optional image for analysis)  
- Tagged, decommissioned, and isolated the instance  

---

### Task 2 — Investigate using system logs

**Goal:** Correlate **host-level signals** (auth logs, user changes, service restarts) with the original alert (**failed SSH attempts**) to decide whether the host shows **post-exploitation** behavior or misconfiguration.

Review logs and indicators. Example findings the lab may highlight:

| Indicator | Severity |
| --------- | -------- |
| New privileged user | **HIGH** |
| Password authentication enabled | **MEDIUM–HIGH** |
| SSH restarts | **MEDIUM** |
| Internal brute force | **HIGH** |
| CloudWatch agent creation | **Normal** |

![Log / investigation screenshot](../../assets/images/lab01-ec2-compromise/12-task2-log-review.png)

**What you're seeing:** Log review in **CloudWatch Logs** (or the log aggregation path the lab uses)—typically **SSH auth**, **useradd/passwd**, or **sshd** events. **How to narrate this in an interview:** You are validating **hypotheses** (“brute force only” vs. “successful break-in”) before declaring **eradication** complete.

**Recommendation:** Disable and block **SSH** where appropriate, and use **AWS Systems Manager Session Manager** for access—**no inbound SSH**, **IAM-controlled** access, auditable via **CloudTrail**.

---

### Task 3 — Mitigate the vulnerability

**Goal:** After containment and analysis, **remove the conditions** that made the incident likely (exposed SSH, weak access patterns) and restore **controlled** administrative access via **Session Manager**.

#### Task 3.1: Enable Session Manager–capable IAM on the instance

**Task 3.1: Add SSM permissions to the instance profile (IAM role)** so the instance can register with **Systems Manager** and accept **Session Manager** sessions (and Run Command).

![SSM-capable instance profile / role](../../assets/images/lab01-ec2-compromise/13-task3-1-ssm-instance-profile.png)

**What you're seeing:** An instance profile whose trust and permissions include **ssm:UpdateInstanceInformation**-style access and attachment to **AmazonSSMManagedInstanceCore** (or the lab’s equivalent managed policy). **Why:** Without this, Session Manager cannot establish a tunnel; operators fall back to SSH—exactly what you are trying to retire.

Attach the role to the instance and **reboot** if needed so permissions take effect.

![Reboot after role attachment](../../assets/images/lab01-ec2-compromise/14-task3-1-reboot.png)

**What you're seeing:** Instance **reboot** so the **SSM Agent** picks up identity/role changes cleanly. **Verify:** Instance should appear as **Managed** in **Fleet Manager** / **Session Manager** after reboot.

#### Task 3.2: Tighten security groups (remove SSH)

**Task 3.2:** Remove **inbound SSH** (TCP/22) from the security group that faces untrusted networks, and transition off the **quarantine** security group per lab steps once the instance is ready for **hardened** production posture.

![Security group rules updated](../../assets/images/lab01-ec2-compromise/15-task3-2-security-groups.png)

**What you're seeing:** **Inbound rules** no longer exposing **22** to broad CIDRs (or removal of SSH entirely). **PCI / NIST angle:** Reduces **remote interactive attack surface** and pushes access through **IAM + TLS**-backed Session Manager channels.

#### Task 3.3: Validate access via Session Manager

**Task 3.3:** Connect via **Session Manager**, validate remediation (e.g., **sshd** config, user accounts, patching state per lab), and **remove the quarantine tag** when the asset is cleared for normal operations.

![Session Manager session](../../assets/images/lab01-ec2-compromise/16-task3-3-session-manager.png)

**What you're seeing:** An active **Session Manager** shell without a public **SSH** listener required. **Audit benefit:** Sessions are **logged** and tied to **IAM principals** in **CloudTrail**, improving **non-repudiation** compared to shared SSH keys.

---

### Task 4 — Automated incident response

**Goal:** Encode the **manual containment** from Task 1 into **repeatable automation** triggered by **log-derived signals** (e.g., repeated SSH failures), so future incidents shrink **mean time to contain**.

**Architecture (high level):**

- **Jump server** simulates **SSH authentication failures** against an **app server**.  
- The app server sends **SSH auth failure** logs to **CloudWatch Logs**.  
- A **subscription filter** forwards matches to a **Log Enrichment Lambda**.  
- The Lambda resolves **internal IP → instance ID** and sends an event to **EventBridge**.  
- An **EventBridge rule** invokes an **Automation Lambda** that performs containment steps.

![End-to-end automation overview](../../assets/images/lab01-ec2-compromise/17-task4-pipeline-overview.png)

**What you're seeing:** A diagram or console view of the **full pipeline** from **log ingestion** to **remediation Lambda**. **Why recruiters care:** It shows you can connect **detection** (logs) to **orchestration** (EventBridge) and **response** (Lambda)—the same pattern as SOAR playbooks, implemented with native AWS services.

**EventBridge / Lambda (source side):**

![EventBridge source and Lambda](../../assets/images/lab01-ec2-compromise/18-task4-eventbridge-lambda-source.png)

**What you're seeing:** Configuration where **EventBridge** receives **custom events** (or CloudWatch Logs–sourced events via subscription) from the **enrichment** function. **Role of enrichment:** Add **instance ID**, **account**, **tags**, or **severity** so the automation target does not guess from a bare IP string.

**Automation target:**

![Automation Lambda as rule target](../../assets/images/lab01-ec2-compromise/19-task4-automation-lambda-target.png)

**What you're seeing:** The **rule target** pointing at the **Automation Lambda** that implements **contain/preserve** steps. **Design point:** Keep the **Lambda** **idempotent** where possible (safe if re-invoked) and **least-privilege** (only EC2/S3/tagging APIs required for the runbook).

#### Task 4.2: Test against another instance (`app-server-2`)

If automation is correct, the response should:

- Capture metadata and upload to **IR-Bucket**  
- Enable **termination protection**  
- Snapshot the instance volume  
- Apply **`Status: Quarantine`** tag  
- Remove the current **IAM role**  
- Replace **App-server-2-SG** with **Quarantine-SG**

You **trigger** failed SSH attempts from the **jump server** so the **subscription filter** fires and the chain runs end-to-end.

![Failed SSH attempts from jump server](../../assets/images/lab01-ec2-compromise/20-task4-2-trigger-from-jump-server.png)

**What you're seeing:** Terminal or console evidence of **deliberate failed SSH** attempts (the **test harness**). **Safety note:** This is **controlled** test traffic in a lab account, not production abuse.

**Result:** Automation runs successfully.

**Metadata in S3:**

![IR bucket — captured metadata](../../assets/images/lab01-ec2-compromise/21-task4-2-s3-metadata-captured.png)

**What you're seeing:** **New objects** in **IR-Bucket** after automation—proving the Lambda executed the **preserve** branch (metadata upload) without waiting for a human.

**Instance tags:**

![Quarantine tags on instance](../../assets/images/lab01-ec2-compromise/22-task4-2-quarantine-tags.png)

**What you're seeing:** **`Status: Quarantine`** (or equivalent) applied by automation—demonstrating **tag-driven** state for SOCs and downstream tooling.

**Security group isolation:**

![Quarantine security group applied](../../assets/images/lab01-ec2-compromise/23-task4-2-quarantine-sg-applied.png)

**What you're seeing:** **App-server-2** now sits behind **Quarantine-SG**, matching the **manual** playbook from Task 1—**repeatable** and **fast**.

---

## Security Insights & Best Practices

- **Preserve evidence early:** snapshots, metadata in **S3**, and **termination protection** reduce accidental loss during IR.  
- **Limit interactive access** on suspect hosts; prefer **SSM Run Command** / **Session Manager** for controlled, auditable execution.  
- **Contain deliberately:** quarantine **security groups**, **strip instance profiles** that enable lateral movement, and use **tags** for workflow state.  
- **Shrink attack surface:** removing **SSH** in favor of **Session Manager** improves **network posture** and **auditability**.  
- **Automate repeatable containment** for high-volume signals (e.g., brute force) using **CloudWatch Logs → Lambda → EventBridge**.  
- **Align to NIST / PCI-DSS:** map actions to detection, containment, eradication, recovery, and logging/access-control expectations.

---

## AWS Security Specialty Exam Relevance

Reinforces **incident response**, **logging and monitoring**, **infrastructure security**, **IAM**, and **event-driven automation** on AWS—typical themes for the **AWS Certified Security — Specialty** exam.

---

## Personal Reflections

Completing the full **preserve → investigate → harden → automate** arc made tradeoffs tangible: evidence steps feel slow until you treat them as **non-negotiable** for credible IR. The lab’s push away from default **SSH** on compromised systems matches real **forensic hygiene**. Building **CloudWatch → Lambda → EventBridge** containment showed how **consistent, scripted response** scales beyond manual runbooks—something worth documenting with explicit **runbook IDs** and **NIST phase mapping** for stakeholders.
