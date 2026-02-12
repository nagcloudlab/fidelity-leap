# Traditional Databases vs Snowflake

## Pre-Workshop Reading | ~10 minutes

If you have worked with a relational database before, this guide shows you what changes when you move to Snowflake -- and what stays the same.

---

## At a Glance

| Dimension | Traditional RDBMS | Snowflake |
|-----------|------------------|-----------|
| **Deployment** | On-premises or self-managed cloud VM | Fully managed SaaS (AWS, Azure, GCP) |
| **Architecture** | Single server or shared-disk cluster | Three independent layers (cloud services, compute, storage) |
| **Storage** | Locally attached disks, SAN, or block storage | Managed cloud object storage (S3, ADLS, GCS) |
| **Compute** | Fixed CPUs and memory on the database server | Elastic virtual warehouses, started and stopped on demand |
| **Scaling up** | Buy bigger hardware, migrate, and restart | Change the warehouse size with a single command |
| **Scaling out** | Complex replication, sharding, or RAC | Add warehouses or enable multi-cluster warehouses |
| **Concurrency** | Shared resources -- more users means slower queries | Each warehouse is isolated -- workloads do not compete |
| **Indexing** | Manually create and maintain B-tree, hash, bitmap indexes | No indexes -- automatic micro-partition pruning |
| **Tuning** | Analyze plans, add hints, rewrite SQL, adjust configs | Minimal -- Snowflake optimizes automatically |
| **Maintenance** | Vacuuming, reindexing, statistics gathering, patching | None -- fully managed |
| **High Availability** | Manual failover, standby replicas, third-party tools | Built-in across availability zones |
| **Disaster Recovery** | Log shipping, backups, manual restoration | Time Travel (up to 90 days), Fail-safe (7 days), replication |
| **Data loading** | INSERT, bulk loaders, vendor-specific utilities | COPY INTO, Snowpipe (continuous), external tables |
| **Semi-structured data** | JSON support varies; often requires workarounds | Native VARIANT type with dot-notation and FLATTEN |
| **Data sharing** | ETL data to another system, or open network ports | Secure Data Sharing with zero data movement |
| **Cost model** | CapEx -- buy servers, pay licenses up front | OpEx -- per-second compute, per-TB storage, no licenses |
| **Administration** | Full-time DBA required | Minimal -- no OS, no patches, no capacity planning |

---

## Deep Dives

### Storage: Managed Disks vs Micro-Partitions

In a traditional database, you manage storage directly. You provision disks, configure RAID, allocate tablespaces, and monitor free space. When you run low, you add disks and redistribute data. The database writes data in pages or blocks that map closely to the physical layout of the disk.

Snowflake stores data in **micro-partitions** -- compressed, columnar, immutable files held in cloud object storage. You never see these files. Snowflake decides how to partition the data, compresses it automatically, and manages all the underlying storage. When you insert or update data, Snowflake writes new micro-partitions and retires old ones.

The result is that storage is practically unlimited, always compressed, and requires zero management from you.

### Compute: Fixed Servers vs Elastic Warehouses

A traditional database server has a fixed amount of CPU and memory. If a heavy report is running, an ETL job has to wait. If the server is undersized for peak traffic, every query suffers. Upgrading means buying new hardware, migrating, and accepting downtime.

Snowflake replaces the fixed server with **virtual warehouses**. A warehouse is a named compute cluster that you create, resize, or drop with a SQL command. You can have as many warehouses as you want. A warehouse starts in seconds, runs your query, and can auto-suspend when idle. If you need more power, you change the size from XS to 6XL. If you need to handle more concurrent users, you enable multi-cluster warehouses that add compute nodes automatically.

Compute and storage are fully independent. You can query a petabyte of data with a small warehouse or a terabyte with a large one -- the choice is yours and changes nothing about how data is stored.

### Concurrency: Bottleneck vs Isolation

On a traditional system, all users share the same CPU and memory. When the marketing team runs a dashboard refresh at the same time the data engineering team runs a heavy transform, both slow down. DBAs respond by queuing, throttling, or partitioning workloads across replicas.

In Snowflake, you assign different workloads to **different warehouses**. The BI dashboards use one warehouse. The ETL pipeline uses another. The data science team gets a third. Each warehouse has its own dedicated compute resources. One workload cannot affect another because they share nothing except the underlying data in storage.

### Indexing and Tuning: Manual Art vs Automatic Pruning

In a traditional database, query performance depends heavily on indexes. You analyze query patterns, create the right indexes, monitor their usage, and rebuild them when they fragment. Missing an index means a full table scan. Adding the wrong one wastes storage and slows writes.

Snowflake has **no indexes**. Instead, every micro-partition automatically records metadata about the data it contains -- minimum and maximum values for each column, the number of distinct values, and null counts. When you run a query with a WHERE clause, Snowflake checks this metadata and skips any micro-partition that cannot contain matching rows. This process is called **pruning**, and it happens automatically on every query without any setup from you.

For workloads that benefit from additional organization, you can define **clustering keys** on large tables to influence how Snowflake groups data into micro-partitions. But this is an optimization, not a requirement.

### Maintenance: DBA Burden vs Managed Service

Running a traditional database means ongoing operational work: patching the OS, upgrading the database engine, running VACUUM or ANALYZE, managing backup schedules, testing disaster recovery, rotating logs, and monitoring disk space. This work is constant and requires specialized skills.

Snowflake eliminates nearly all of it. There is no OS to patch, no engine to upgrade, no vacuum to run, no backups to schedule, no disks to monitor. Snowflake handles software updates transparently (you get new features without downtime), manages all storage automatically, and provides built-in replication and failover. Your operational responsibility is limited to managing users, roles, warehouses, and data -- the work that is specific to your organization.

### Cost Model: CapEx vs Pay-per-Use

Traditional databases involve large up-front costs: servers, storage, network equipment, software licenses, and the staff to run them. You pay for peak capacity even during off-hours when utilization is low.

Snowflake flips this to **pay-per-use**. You pay for compute by the second (measured in credits) and for storage by the terabyte per month. When a warehouse is suspended, you pay nothing for compute. You can run a large warehouse for five minutes during peak load and a small warehouse the rest of the day. There are no licenses, no hardware, and no long-term commitments beyond your storage.

---

## What Stays the Same

If you know SQL and relational databases, much of your knowledge transfers directly:

- **SQL** -- Snowflake supports ANSI SQL. SELECT, JOIN, GROUP BY, window functions, CTEs, subqueries -- it all works.
- **Relational model** -- data lives in tables with columns and rows. You create schemas to organize tables. You build views on top of tables.
- **ACID transactions** -- Snowflake guarantees atomicity, consistency, isolation, and durability for DML operations.
- **Role-based access control** -- you create roles, grant privileges, and assign roles to users. The model follows the same principles you already know.
- **Stored procedures and functions** -- you can write procedural logic in SQL, JavaScript, Python, Java, or Scala.
- **Data types** -- VARCHAR, NUMBER, DATE, TIMESTAMP, BOOLEAN, and more. The core types are familiar.

You do not have to unlearn SQL to use Snowflake. You have to unlearn the infrastructure around it.

---

## Concepts That Don't Exist in Snowflake

If you are coming from a traditional database, you may look for features that Snowflake does not have -- because it does not need them.

| Traditional Concept | Snowflake Equivalent |
|--------------------|---------------------|
| B-tree / Hash indexes | Automatic micro-partition pruning |
| Table partitioning (RANGE, LIST, HASH) | Automatic micro-partitioning (optional clustering keys) |
| Buffer pool / Shared memory | Managed by Snowflake -- not configurable |
| VACUUM / ANALYZE | Not needed -- handled automatically |
| Tablespaces | Not needed -- storage is managed |
| Connection pooling | Not needed at the warehouse level -- each warehouse scales independently |
| Manual backups | Time Travel + Fail-safe (automatic) |
| Read replicas | Additional warehouses querying the same data |
| Log shipping / WAL | Built-in replication and failover |
| Hints (/*+ ... */) | Not supported -- the optimizer handles it |

---

## Next Steps

- **Next reading:** [Snowflake Architecture](03-snowflake-architecture.md) -- see how the three-layer architecture works under the hood.
- **Ready to start?** Jump to [Lab 01 -- Getting Started](lab-01-getting-started/guide.md) to begin hands-on work.
