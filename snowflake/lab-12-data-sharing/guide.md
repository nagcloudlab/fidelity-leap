# Lab 12: Data Sharing

## Objective

Learn how to use Snowflake's **Secure Data Sharing** to share live data across Snowflake
accounts without copying, moving, or transferring any data. By the end of this lab you will
understand the provider-consumer model, create shares, build secure views, explore reader
accounts, and know how the Snowflake Marketplace works.

## Duration

25 minutes

## Prerequisites

| Requirement | Details |
|---|---|
| Snowflake Account | A trial or paid account with **ACCOUNTADMIN** access |
| Prior Labs | Familiarity with databases, schemas, tables, and views (Labs 1-4) |
| Browser | Snowsight UI or a SQL client connected to Snowflake |

> **Important:** Full end-to-end data sharing requires two separate Snowflake accounts.
> This lab focuses on the **provider side** setup. Consumer-side steps are explained
> conceptually so you understand the complete workflow.

---

## Key Concepts

### What Is Secure Data Sharing?

Snowflake's Secure Data Sharing lets a **data provider** grant read-only access to selected
objects (tables, secure views, secure UDFs) to one or more **data consumers** -- all without
copying or moving a single byte of data.

### Core Terminology

| Term | Definition |
|---|---|
| **Share** | A named Snowflake object that encapsulates the grants on databases, schemas, and objects you want to share. |
| **Provider** | The Snowflake account that owns the data and creates the share. |
| **Consumer** | The Snowflake account that receives the share and creates a read-only database from it. |
| **Secure View** | A view whose SQL definition is hidden from consumers. Essential for sharing filtered or restricted data. |
| **Secure UDF** | A user-defined function whose logic is hidden from consumers, used to share computed results. |
| **Reader Account** | A managed Snowflake account created by the provider for consumers who do not have their own Snowflake account. |
| **Listing** | A packaged offering of shared data, published privately or to the Snowflake Marketplace. |
| **Snowflake Marketplace** | A catalog where providers publish data products that any Snowflake customer can discover and consume. |

### Why Secure Data Sharing?

- **No data movement or copying** -- consumers query the provider's storage directly.
- **Real-time access** -- consumers always see the latest data; no stale extracts.
- **Zero cost for the provider** -- the consumer pays only for the compute they use to query.
- **Governed** -- providers control exactly which objects are visible and can revoke access instantly.

---

## How Data Sharing Works

The workflow follows three stages:

```
Provider Side                           Consumer Side
---------------------                   ----------------------
1. CREATE SHARE              --->
2. GRANT objects TO SHARE    --->
3. ALTER SHARE SET ACCOUNTS   --->      4. SHOW SHARES (inbound)
                                        5. CREATE DATABASE FROM SHARE
                                        6. Query the shared database
```

### Step-by-Step Flow

1. **Provider creates a share** -- `CREATE SHARE share_name;`
2. **Provider grants objects** -- grants usage on the database, schema, and select privilege
   on tables or secure views to the share.
3. **Provider adds consumer accounts** -- `ALTER SHARE ... ADD ACCOUNTS = consumer_account;`
4. **Consumer discovers the share** -- `SHOW SHARES;` reveals inbound shares.
5. **Consumer creates a database from the share** -- this database is read-only and
   points to the provider's storage.
6. **Consumer queries the data** -- standard SELECT statements; the data is always live.

---

## Use Cases

| Use Case | Example |
|---|---|
| **Partner data exchange** | Share order data with a logistics partner so they see shipment requests in real time. |
| **Monetize data** | Publish weather, financial, or demographic data sets on the Snowflake Marketplace. |
| **Inter-department sharing** | A central data team shares curated data products with marketing, finance, and engineering -- each through secure views that filter to their scope. |
| **Regulatory reporting** | Share audit-ready data sets with external auditors without creating file extracts. |

---

## Step-by-Step Instructions

### Step 1 -- Prepare the Source Data (3 min)

Open the SQL file `lab-12.sql` in Snowsight or your SQL client. Run **Section 1** to create
the sample tables that represent data you want to share: a products table, an orders table,
and a customers table.

### Step 2 -- Create Secure Views (3 min)

Run **Section 2**. Secure views are the recommended way to share data because:

- The view definition (SQL text) is hidden from consumers, protecting business logic.
- You can filter rows or mask columns so each consumer sees only what they should.

Verify that the secure views return the expected results.

### Step 3 -- Create a Secure UDF (2 min)

Run **Section 3** to create a secure user-defined function. Secure UDFs hide the function
body from consumers while still letting them call the function on shared data.

### Step 4 -- Create a Share and Grant Objects (4 min)

Run **Section 4**. This is the core of data sharing:

1. `CREATE SHARE` creates the share object.
2. A series of `GRANT` statements add the database, schema, and individual objects to the
   share.
3. `SHOW SHARES` and `DESCRIBE SHARE` let you inspect what is in the share.

### Step 5 -- Add Consumer Accounts to the Share (2 min)

Run **Section 5**. In a real scenario you would replace the placeholder account identifier
with an actual Snowflake account locator. This step is shown conceptually.

### Step 6 -- Explore Reader Accounts (3 min)

Run **Section 6**. A reader account is a lightweight managed Snowflake account for
consumers who do not have their own Snowflake account. The provider pays for storage and
compute. The section shows the `CREATE MANAGED ACCOUNT` syntax and explains the
limitations.

### Step 7 -- Understand the Consumer Side (3 min)

Read through **Section 7** in the SQL file. Because you need a second Snowflake account to
actually consume a share, this section is commented out but fully annotated so you
understand the commands the consumer would run.

### Step 8 -- Snowflake Marketplace and Listings (3 min)

Read **Section 8**. This conceptual walkthrough explains how providers publish listings to
the Marketplace and how consumers discover and attach them.

### Step 9 -- Revoke Access and Cleanup (2 min)

Run **Section 9** to revoke grants, drop the share, and clean up all lab objects.

---

## Best Practices

1. **Always share through secure views, not raw tables.** Secure views let you filter rows,
   mask columns, and hide business logic.
2. **Use secure UDFs for computed or derived data.** This keeps proprietary formulas hidden.
3. **Grant the minimum required privileges.** Only add the specific objects consumers need.
4. **Audit shares regularly.** Use `SHOW SHARES` and `DESCRIBE SHARE` to review what is
   exposed.
5. **Prefer direct sharing over reader accounts.** Reader accounts add management overhead
   and cost because the provider pays for compute.
6. **Name shares descriptively.** Include the audience or purpose in the share name
   (e.g., `PARTNER_LOGISTICS_SHARE`).
7. **Use listings for broader distribution.** If you want to share data with many consumers
   or monetize it, publish a listing rather than managing individual shares.
8. **Test with a second account before going live.** Verify the consumer experience by
   creating a trial account and consuming your own share.
9. **Document what each share contains.** Maintain a data dictionary so consumers understand
   the schema and semantics.
10. **Revoke access promptly when partnerships end.** Remove consumer accounts from shares
    as soon as they no longer need access.

---

## Review Questions

1. **What is the fundamental difference between Snowflake's Secure Data Sharing and
   traditional file-based data sharing (e.g., SFTP, email, S3 buckets)?**

2. **Why should you use secure views instead of sharing raw tables directly?**

3. **What three levels of GRANT are required to make a table visible in a share?**
   *(Hint: database, schema, table.)*

4. **What is a reader account, and when would you create one instead of sharing directly
   with another Snowflake account?**

5. **If a provider inserts new rows into a shared table at 10:00 AM, when will the consumer
   see those rows?**

6. **Who pays for the compute when a consumer queries shared data?**

7. **Can a consumer modify (INSERT, UPDATE, DELETE) data in a database created from a
   share? Why or why not?**

8. **Name two use cases where publishing a listing on the Snowflake Marketplace is more
   appropriate than creating a private share.**

9. **What does the DESCRIBE SHARE command show, and why is it useful?**

10. **What happens to the consumer's database when the provider drops a share?**

---

## Summary

In this lab you learned how Snowflake's Secure Data Sharing enables zero-copy, real-time
data sharing between accounts. You created secure views and UDFs, built a share, granted
objects to it, explored reader accounts, and reviewed the Snowflake Marketplace. The key
takeaway is that Snowflake eliminates the need to extract, transfer, and load data for
sharing -- consumers always see the live, governed data that providers choose to expose.
