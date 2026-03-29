# Lab 03A - VPC-only S3 access point, gateway endpoint, and bucket policy

**AWS services:** Amazon VPC, Amazon S3 (access points), **gateway VPC endpoints**, IAM, Amazon EC2

**Screenshots:** [`../../assets/images/lab03a-vpc-s3-access-point/`](../../assets/images/lab03a-vpc-s3-access-point/)

---

## Overview

You use **S3 access points** together with a **gateway VPC endpoint** and **endpoint policy** so that **only traffic from a specific VPC** can reach shared datasets, and so that **S3 access is limited to requests made through the access point** (not arbitrary bucket-global URLs). A **bucket policy** further restricts access to the **VPC context** (e.g., **VPC ID**), supporting **least privilege** for data access from application subnets.

**How to read the walkthrough:** The screenshots follow the **request path** from an **EC2 instance** in your VPC to **S3**. After each image, the notes explain **which hop** in that path is being constrained and **why** that layer matters for defense in depth.

---

## Objectives

By the end of this lab, you should understand how to:

- Explain how **VPC network origin** on an access point **rejects** requests that do not originate from the designated **VPC**
- Create a **VPC-only access point** tied to an **S3 bucket**
- Create a **gateway VPC endpoint** for **S3** with a policy that **allows access only via the access point ARN**
- Use **route tables** so **EC2** traffic to the access point goes through the **VPC endpoint**
- Apply a **bucket policy** that scopes access to your **VPC** and validate **list/get** via the access point from **EC2**

---

## AWS Services Used

| Area | Services |
| ---- | -------- |
| Networking | **Amazon VPC**, **route tables**, **gateway VPC endpoints** |
| Storage & access | **Amazon S3**, **S3 access points** |
| Compute | **Amazon EC2** (CLI: `aws s3api` against access point) |

---

## Step-by-Step Walkthrough

### Conceptual steps (Steps 1–8)

![Architecture — access points and VPC endpoint](../../assets/images/lab03a-vpc-s3-access-point/01.png)

**What you're seeing:** The **reference architecture**—shared **S3 bucket**, **access point** as the **narrow doorway**, **gateway endpoint** so traffic stays on the **AWS network**, and **policies** at endpoint and bucket. **Why draw this first:** In design reviews, reviewers will ask “**where** is enforcement?”—this diagram answers **network path** vs **identity** vs **resource policy**.

- **Step 1:** Streamline application access using **access points** plus **VPC endpoint policies** for shared datasets.
- **Step 2:** Access points provide **distinct hostnames** with their own **permissions** and **network controls**.
- **Step 3:** A **VPC** network origin causes S3 to **reject** requests not from that VPC.
- **Step 4:** Create a **VPC-only access point** on the bucket.
- **Step 5:** Add a **gateway VPC endpoint** for S3.
- **Step 6:** Endpoint policy **allows S3 only through the access point**.
- **Step 7:** **Route tables** send access-point traffic to the endpoint.
- **Step 8:** Optional second endpoint / policy pattern for **other subnets**.

**Interview tip:** Say the path aloud once: **instance → route table (prefix list) → gateway endpoint → S3 API → access point → bucket**.

### Hands-on configuration

#### Baseline: direct bucket access

**Goal:** Show that **unrestricted** or **non-endpoint** access patterns behave differently from the **locked-down** design—your “before” picture for comparison.

**Access the bucket without the access point** (baseline / comparison):

![Direct bucket access attempt](../../assets/images/lab03a-vpc-s3-access-point/02.png)

**What you're seeing:** A **list/get** attempt using the **bucket name** or **bucket URL** style access that the lab uses as a contrast. **Why:** Proves the **access point + endpoint** design is doing work, not just renaming URLs.

#### Create and scope the access point

**Goal:** Create an **S3 access point** bound to the bucket and set **network origin** to **VPC only** so the **access point hostname** only accepts calls that S3 attributes to that VPC.

**Create the access point:**

![Create S3 access point](../../assets/images/lab03a-vpc-s3-access-point/03.png)

**What you're seeing:** **Create access point** wizard—name, bucket association, and **block public access** settings inherited or set per lab. **Key idea:** Access points are **separate resource ARNs** for IAM and policy conditions.

**Associate the access point with the VPC** where the instance runs:

![Associate access point to VPC](../../assets/images/lab03a-vpc-s3-access-point/04.png)

**What you're seeing:** **VPC** selected as the **network origin** for the access point. **Effect:** Requests not presenting that **network context** fail at S3 even if credentials are valid—**defense beyond IAM**.

#### Gateway endpoint for S3

**Goal:** Force **S3-bound** traffic from private subnets to use the **AWS backbone** via a **gateway endpoint**, and prepare to attach an **endpoint policy** that is **stricter** than “allow all S3.”

**Create the gateway endpoint** for S3:

![Gateway VPC endpoint for S3](../../assets/images/lab03a-vpc-s3-access-point/05.png)

**What you're seeing:** **Create VPC endpoint** → **S3** → **Gateway** type, linked to **route tables** for subnets that host your app. **Why gateway for S3:** No hourly endpoint charge in the same way as **interface** endpoints; **prefix list** routes are added automatically to selected route tables.

#### Endpoint policy: only via access point ARN

**Goal:** Even if an identity **could** call S3, the **VPC endpoint** only permits API calls that target **your access point ARN** (pattern varies slightly by action—lab shows the effective JSON).

**Endpoint policy** — allow calls only when using the **access point ARN** (substitute your ARNs):

![VPC endpoint policy — access point restriction](../../assets/images/lab03a-vpc-s3-access-point/06.png)

![VPC endpoint policy — continued](../../assets/images/lab03a-vpc-s3-access-point/07.png)

**What you're seeing:** **Endpoint policy** JSON referencing the **access point** resource and allowing **s3:GetObject** / **List** (or equivalent) **only** along that path. **Second shot:** Often **additional statements** or **conditions**—e.g., **aws:PrincipalArn**, **aws:SourceVpc**, or action list continuation.

**Mistake to avoid:** Confusing **endpoint policy** (applied at the **VPC endpoint**) with **bucket policy** (applied at the **bucket**). You need **both** to align for least privilege.

#### Validate access through the access point

**Goal:** Confirm that from **EC2**, **`aws s3api`** (or SDK) calls using the **access point ARN** succeed while **misrouted** or **direct bucket** calls fail once policies are fully applied.

**Test access via the access point:**

![Test access through access point](../../assets/images/lab03a-vpc-s3-access-point/08.png)

**What you're seeing:** Successful **list** or **get** using **access point** addressing. **Verify:** Command uses **access point** alias or ARN form the lab specifies—not the raw bucket name.

#### Bucket policy: VPC context

**Goal:** Add a **bucket policy** **condition** using **`aws:SourceVpc`** (or **`aws:VpcSourceIp`** in other patterns) so the **bucket** itself refuses requests outside your VPC—even if someone misconfigures an endpoint elsewhere.

**Bucket policy** — restrict the bucket so it is reachable only from this **VPC** (resource policy with **VPC ID**):

![Bucket policy — VPC-scoped access](../../assets/images/lab03a-vpc-s3-access-point/09.png)

**What you're seeing:** **`StringEquals`** on **`aws:SourceVpc`** (or equivalent) with your **VPC ID**. **Triple lock recap:** (1) **access point** network origin, (2) **endpoint policy** to access point ARNs, (3) **bucket policy** VPC condition.

#### CLI listing / download via access point alias

**Goal:** Show **repeatable** operator steps using the **access point alias**—what automation and apps would mirror.

**CLI listing / download** using the access point alias:

![CLI list and download via access point](../../assets/images/lab03a-vpc-s3-access-point/10.png)

**What you're seeing:** **`aws s3api list-objects-v2`** / **`get-object`** (or `cp`) with **access point** hostname or ARN. **Runbook value:** Same commands drop into **CI** or **instance user-data** with **no public internet** dependency for S3 retrieval.

---

## Security Insights & Best Practices

- **Access points** reduce **blast radius** compared with a single **bucket-wide** permission model.
- **Gateway endpoints** keep **S3 traffic on the AWS network**; policies can **bind** that path to **specific ARNs** (access points).
- **Bucket policies** that assert **VPC context** help enforce **“only from my network”** in addition to **identity** policies.

---

## AWS Security Specialty Exam Relevance

Touches **VPC connectivity**, **S3 access points**, **endpoint policies**, and **defense in depth** for data paths.

---

## Personal Reflections

The combination **access point + endpoint policy + bucket policy** is easy to mix up in exams and in design reviews—drawing the **request path** (instance → route table → endpoint → access point → bucket) once saves a lot of confusion later.
