# Lab 03A - VPC-only S3 access point, gateway endpoint, and bucket policy

**AWS services:** Amazon VPC, Amazon S3 (access points), **gateway VPC endpoints**, IAM, Amazon EC2

**Screenshots:** [`../../assets/images/lab03a-vpc-s3-access-point/`](../../assets/images/lab03a-vpc-s3-access-point/)

---

## Overview

You use **S3 access points** together with a **gateway VPC endpoint** and **endpoint policy** so that **only traffic from a specific VPC** can reach shared datasets, and so that **S3 access is limited to requests made through the access point** (not arbitrary bucket-global URLs). A **bucket policy** further restricts access to the **VPC context** (e.g., **VPC ID**), supporting **least privilege** for data access from application subnets.

## Objectives

By the end of this lab, you should understand how to:

- Explain how **VPC network origin** on an access point **rejects** requests that do not originate from the designated **VPC**
- Create a **VPC-only access point** tied to an **S3 bucket**
- Create a **gateway VPC endpoint** for **S3** with a policy that **allows access only via the access point ARN**
- Use **route tables** so **EC2** traffic to the access point goes through the **VPC endpoint**
- Apply a **bucket policy** that scopes access to your **VPC** and validate **list/get** via the access point from **EC2**

## AWS Services Used

| Area | Services |
| ---- | -------- |
| Networking | **Amazon VPC**, **route tables**, **gateway VPC endpoints** |
| Storage & access | **Amazon S3**, **S3 access points** |
| Compute | **Amazon EC2** (CLI: `aws s3api` against access point) |

## Step-by-Step Walkthrough

### Conceptual steps (Steps 1–8)

![Architecture — access points and VPC endpoint](../../assets/images/lab03a-vpc-s3-access-point/01.png)

- **Step 1:** Streamline application access using **access points** plus **VPC endpoint policies** for shared datasets.
- **Step 2:** Access points provide **distinct hostnames** with their own **permissions** and **network controls**.
- **Step 3:** A **VPC** network origin causes S3 to **reject** requests not from that VPC.
- **Step 4:** Create a **VPC-only access point** on the bucket.
- **Step 5:** Add a **gateway VPC endpoint** for S3.
- **Step 6:** Endpoint policy **allows S3 only through the access point**.
- **Step 7:** **Route tables** send access-point traffic to the endpoint.
- **Step 8:** Optional second endpoint / policy pattern for **other subnets**.

### Hands-on configuration

**Access the bucket without the access point** (baseline / comparison):

![Direct bucket access attempt](../../assets/images/lab03a-vpc-s3-access-point/02.png)

**Create the access point:**

![Create S3 access point](../../assets/images/lab03a-vpc-s3-access-point/03.png)

**Associate the access point with the VPC** where the instance runs:

![Associate access point to VPC](../../assets/images/lab03a-vpc-s3-access-point/04.png)

**Create the gateway endpoint** for S3:

![Gateway VPC endpoint for S3](../../assets/images/lab03a-vpc-s3-access-point/05.png)

**Endpoint policy** — allow calls only when using the **access point ARN** (substitute your ARNs):

![VPC endpoint policy — access point restriction](../../assets/images/lab03a-vpc-s3-access-point/06.png)

![VPC endpoint policy — continued](../../assets/images/lab03a-vpc-s3-access-point/07.png)

**Test access via the access point:**

![Test access through access point](../../assets/images/lab03a-vpc-s3-access-point/08.png)

**Bucket policy** — restrict the bucket so it is reachable only from this **VPC** (resource policy with **VPC ID**):

![Bucket policy — VPC-scoped access](../../assets/images/lab03a-vpc-s3-access-point/09.png)

**CLI listing / download** using the access point alias:

![CLI list and download via access point](../../assets/images/lab03a-vpc-s3-access-point/10.png)

## Security Insights & Best Practices

- **Access points** reduce **blast radius** compared with a single **bucket-wide** permission model.
- **Gateway endpoints** keep **S3 traffic on the AWS network**; policies can **bind** that path to **specific ARNs** (access points).
- **Bucket policies** that assert **VPC context** help enforce **“only from my network”** in addition to **identity** policies.

## AWS Security Specialty Exam Relevance

Touches **VPC connectivity**, **S3 access points**, **endpoint policies**, and **defense in depth** for data paths.

## Personal Reflections

The combination **access point + endpoint policy + bucket policy** is easy to mix up in exams and in design reviews—drawing the **request path** (instance → route table → endpoint → access point → bucket) once saves a lot of confusion later.
