# Lab 02 - KMS CMK and S3 bucket policy for encryption enforcement

**AWS services:** AWS KMS, Amazon S3, IAM, Amazon EC2 (for CLI / variable setup)

**Frameworks:** NIST, PCI-DSS (data protection and key management align with both)

Screenshots are stored in this repo under [`../../assets/images/lab02-kms-s3-encryption/`](../../assets/images/lab02-kms-s3-encryption/).

---

## Overview

You implement **defense in depth** for object storage: start from **SSE-S3** default encryption, introduce a **customer managed KMS key (CMK)** with **automatic key rotation**, switch the bucket to **SSE-KMS**, and finally enforce—via **bucket policy**—that objects can only be uploaded when clients specify **KMS encryption**. That closes the gap where unencrypted or wrongly encrypted uploads would otherwise succeed.

**How to read the walkthrough:** Each step explains **what** you configure, **why** it matters for key custody and compliance, and **what** the screenshot is meant to evidence. That turns the console trail into a story a recruiter or auditor can follow without guessing.

---

## Objectives

By the end of this lab, you should be able to:

- Create an **AWS KMS customer managed key** and enable **automatic rotation**
- Grant an **IAM role** appropriate **administrative** and **usage** permissions on the key
- Turn on and verify **default encryption** for an **S3** bucket (**lab-bucket**) using **SSE-KMS**
- Upload objects and **verify** the encryption headers / metadata in the console
- Attach a **bucket policy** that **denies** `s3:PutObject` unless the request uses your **KMS key**
- Confirm **Access Denied** for noncompliant uploads and **success** when using the correct encryption parameters

---

## AWS Services Used

| Area | Services |
| ---- | -------- |
| Encryption & keys | **AWS KMS** (CMK, rotation, grants / policies) |
| Object storage | **Amazon S3** (default encryption, bucket policy, objects) |
| Access control | **IAM** (roles for key and workload identity) |
| Compute (optional path in lab) | **Amazon EC2** (environment variables for bucket and key ARNs) |

---

## Step-by-Step Walkthrough

### Context and tasks

The lab positions you to move from **AWS-managed encryption** (simple, less customer control) to **customer-managed keys** and **mandatory** encryption on upload—patterns auditors often ask to demonstrate for **data at rest** in object storage.

High-level diagram / console context from the lab:

![Lab context](../../assets/images/lab02-kms-s3-encryption/01.png)

**What you're seeing:** The scenario wiring—**EC2** (or a principal using the lab role), **S3 bucket**, and **KMS**—and the tasks you will execute in order.

**Tasks (summary):**

- Create an AWS KMS **customer managed key**
- Turn on encryption for data stored in **S3**, then **require** KMS on `PutObject`

### Step 1 — Review current bucket encryption (SSE-S3)

**Goal:** Establish a **baseline**. **SSE-S3** uses keys managed entirely by S3. It encrypts data at rest but does not give you a **customer-managed key policy**, **separate CloudTrail fields for KMS**, or the same **cryptographic separation** as **SSE-KMS** for some compliance narratives.

Inspect **default encryption** for the bucket while it still uses **SSE-S3**:

![Default encryption — SSE-S3 review](../../assets/images/lab02-kms-s3-encryption/02.png)

**What you're seeing:** The bucket’s **default encryption** panel showing **SSE-S3** (Amazon S3-managed keys). **Interview angle:** Contrast “**encryption exists**” vs “**I control the key lifecycle and who can use it**.”

### Step 2 — Create a KMS CMK and enable rotation

**Goal:** Create a **CMK** whose **key policy** you own, assign **administrators** (who manage the key) and **users** (who can call **Encrypt/Decrypt/GenerateDataKey** for S3), and turn on **automatic annual rotation** of **backing keys** for the CMK.

Create the **CMK**, assign **key administrators** and **key users** (same **IAM role** as in the lab), then enable **automatic key rotation**.

![KMS key — admin and usage IAM role](../../assets/images/lab02-kms-s3-encryption/03.png)

**What you're seeing:** **Key policy** or **Define key administrative permissions** / **usage permissions** screens with the lab’s **IAM role** trusted for admin and/or cryptographic use. **Why it matters:** Misconfigured key policies are a common reason **S3** shows **AccessDenied** when calling KMS—even if the S3 bucket policy allows the upload.

![KMS key — automatic rotation](../../assets/images/lab02-kms-s3-encryption/04.png)

**What you're seeing:** **Automatic key rotation** enabled on the CMK. **Why it matters:** Rotation limits exposure if a backing key were ever compromised and supports **NIST**-style key-management expectations; it does **not** re-encrypt all existing S3 objects automatically—new data keys are used for **new** operations.

### Step 3 — Configure environment variables (EC2)

**Goal:** Avoid copy-paste errors when testing with the **CLI**: store **bucket name** and **KMS key ARN** in the shell so `aws s3api` commands stay consistent and repeatable.

On the **EC2** instance, set variables for the **S3 bucket name** and **KMS key ARN** so CLI commands stay consistent.

![EC2 — bucket and KMS key variables](../../assets/images/lab02-kms-s3-encryption/05.png)

**What you're seeing:** `export` (or equivalent) of **BUCKET** / **KEY_ARN** (names vary by lab). **Verify:** `echo` the variables before running uploads so failures are not due to typos in ARNs.

### Step 4 — Update default encryption on `lab-bucket`

**Goal:** Change the bucket’s **default encryption** so **new objects** use **SSE-KMS** with your **CMK** unless the client overrides with an allowed configuration. This aligns the **bucket default** with your **key governance** story.

Change **default encryption** for **lab-bucket** to use your **KMS CMK** (**SSE-KMS**).

![S3 — default encryption type updated to KMS](../../assets/images/lab02-kms-s3-encryption/06.png)

**What you're seeing:** **Default encryption** set to **SSE-KMS** with your key selected. **Caveat:** Default encryption does **not** by itself **deny** clients that omit encryption headers—some APIs can still succeed with defaults; **Step 7** closes that with a **deny** policy.

### Step 5 — Confirm default encryption settings

**Goal:** **Evidence** step—capture proof in the console (or CLI output) that the bucket **displays** the expected **KMS key** for default encryption.

In **Default encryption**, verify **Encryption type** reflects **SSE-KMS** and the expected **KMS key**.

![S3 — default encryption confirmation](../../assets/images/lab02-kms-s3-encryption/07.png)

**What you're seeing:** Confirmation view of **SSE-KMS** + key ARN/alias. **Auditor ask:** “Show me where the bucket is bound to **this** CMK.”

### Step 6 — Upload objects and verify encryption

**Goal:** Prove that **uploaded objects** are encrypted with **KMS** at the **object** level (metadata / properties), not only at the bucket default screen.

Upload new objects and confirm in the console that **encryption** is **AWS-KMS** with your key.

![Upload and encryption verification (1)](../../assets/images/lab02-kms-s3-encryption/08.png)

![Upload and encryption verification (2)](../../assets/images/lab02-kms-s3-encryption/09.png)

**What you're seeing:** Object **Properties** → **Encryption** showing **AWS-KMS** and the **correct key**. **Why two shots:** Often one shows **upload** and the other **object detail** or **list** view—together they show **end-to-end** application of default encryption.

### Step 7 — Require KMS on every upload (bucket policy)

**Goal:** Add a **resource-based deny** (or condition key constraint) so `s3:PutObject` **fails** unless the request uses **SSE-KMS** with **your** key. This is the control that makes encryption **mandatory**, not **best effort**.

Add a **bucket policy** that **denies** uploads unless **SSE-KMS** uses your key. Replace the **bucket ARN** (and key ARN) with your environment’s values.

![Bucket policy — enforce KMS on PutObject](../../assets/images/lab02-kms-s3-encryption/10.png)

**What you're seeing:** JSON policy using **`Deny`** with **`s3:x-amz-server-side-encryption`** and **`s3:x-amz-server-side-encryption-aws-kms-key-id`** (or equivalent conditions). **PCI / NIST angle:** You can point to a **single policy document** that **technically enforces** cryptographic parameters, not only **recommends** them.

### Step 8 — Attach the policy and test behavior

**Goal:** **Negative and positive testing**—security controls are only credible when **misuse fails** and **compliant use succeeds**.

Attach the policy to the bucket, then attempt uploads **without** proper encryption (**Access Denied** as expected) and **with** the correct method (**success**).

![Attach policy / CLI workflow](../../assets/images/lab02-kms-s3-encryption/11.png)

**What you're seeing:** Policy **saved** on the bucket and/or CLI session preparing **test** `put-object` calls. **Best practice:** Run **both** tests and keep **command history** (redacted) for runbooks.

![Access denied on noncompliant upload](../../assets/images/lab02-kms-s3-encryption/12.png)

**What you're seeing:** **`AccessDenied`** (or `403`) when encryption headers or key ID are wrong or missing. **Story for interviews:** “We **proved** the bucket **rejects** weak uploads.”

![Successful upload with correct encryption](../../assets/images/lab02-kms-s3-encryption/13.png)

**What you're seeing:** **HTTP 200** / success path when **`--server-side-encryption aws:kms`** and **`--ssekms-key-id`** (or console equivalent) match policy expectations.

![Final verification](../../assets/images/lab02-kms-s3-encryption/14.png)

**What you're seeing:** Final object list or properties confirming **compliant** objects after enforcement. **Close-out:** Default encryption + **deny policy** + **KMS rotation** = layered **preventive** and **detective** (via **CloudTrail** KMS events) story.

---

## Security Insights & Best Practices

- **Customer managed keys** give you **explicit key policies**, **rotation**, and **audit trails** separate from AWS-owned keys.
- **Default encryption** protects **new objects** but does not always stop clients from **omitting** encryption headers—**bucket policies** close that gap.
- **Least privilege** on the KMS key: separate **administrators** vs **users**, and scope **usage** to the roles that need it.
- **PCI-DSS** and **NIST** both emphasize **strong cryptography**, **key management**, and **demonstrable controls**—a deny-based bucket policy is easy to evidence in assessments.

---

## AWS Security Specialty Exam Relevance

Reinforces **data protection**, **KMS key policies**, **S3 encryption modes** (SSE-S3 vs SSE-KMS), and **resource-based policies**—common **AWS Certified Security — Specialty** topics.

---

## Personal Reflections

Moving from **“encryption on by default”** to **“encryption provably required”** is a small policy change with a large compliance payoff. Pairing **KMS rotation** with **S3 deny statements** makes the control **testable** and **repeatable**, which matters more than any single console screenshot.
