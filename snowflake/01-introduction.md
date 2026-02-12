# Introduction to Snowflake

## Pre-Workshop Reading | ~8 minutes

---

## The Problem

Every organization generates more data than it did a year ago. Traditional databases were designed for a world where data volumes were predictable and workloads were steady. As data grows, those systems hit a wall:

- **Data volume outpaces storage** -- adding disks is expensive, slow, and limited by the hardware you own.
- **Compute is fixed** -- a busy report and a massive data load compete for the same CPU and memory. One wins; the other waits.
- **Storage and compute are tightly coupled** -- you cannot scale one without scaling the other, so you over-provision both.
- **Administration is constant** -- someone must plan capacity, tune indexes, manage backups, patch operating systems, and handle failovers.
- **Concurrency suffers** -- as more users and applications query the same system, performance degrades for everyone.

Cloud computing changed what is possible. Snowflake was built from scratch to take advantage of it.

---

## What Is Snowflake?

Snowflake is a **cloud-native data platform** delivered as a fully managed service (SaaS). It runs entirely in the cloud -- there is no hardware to buy, no software to install, and no infrastructure to manage.

Key characteristics:

- **Cloud-native** -- built for the cloud, not ported from on-premises software. Snowflake runs on AWS, Azure, and GCP infrastructure.
- **Multi-cloud** -- you choose your cloud provider and region. Your data stays where you put it, but Snowflake's architecture is the same everywhere.
- **Separation of storage and compute** -- storage and compute scale independently. You can store petabytes of data and spin up compute only when you need it.
- **Elastic compute** -- warehouses (compute clusters) start in seconds, scale up or out on demand, and suspend automatically when idle.
- **Near-zero administration** -- no indexes to build, no storage to allocate, no vacuuming, no manual tuning. Snowflake handles it.
- **Per-second billing** -- you pay for compute by the second (with a 60-second minimum) and for storage by the terabyte per month.
- **Secure by default** -- all data is encrypted at rest and in transit. Role-based access control is built in from day one.

---

## What Snowflake Is NOT

Snowflake is often misunderstood. A few clarifications:

- **Not a traditional database running on a VM** -- Snowflake is not PostgreSQL or Oracle installed in the cloud. Its architecture is purpose-built and shares nothing with legacy systems.
- **Not Hadoop or a data lake** -- Snowflake is not a distributed file system. It stores structured and semi-structured data in a managed, optimized format. You query it with standard SQL, not MapReduce.
- **Not an ETL tool** -- Snowflake can load, transform, and query data, but it is not a replacement for dedicated orchestration tools like Airflow or dbt. It is where data lands and gets queried.
- **Not just a data warehouse** -- Snowflake supports data warehousing, data engineering, data science, data applications, and data sharing. The term "data platform" reflects this breadth.

---

## Where Snowflake Fits

Snowflake sits at the center of a modern data architecture. Data flows in from many sources, gets stored and processed in Snowflake, and is consumed by tools and people downstream.

```
  DATA SOURCES                    SNOWFLAKE                     CONSUMPTION
 ┌──────────────┐            ┌─────────────────┐           ┌──────────────────┐
 │ Applications │──┐         │                 │      ┌───>│ BI / Dashboards  │
 │ Databases    │  │         │   Cloud Services│      │    │ (Tableau, etc.)  │
 │ SaaS Tools   │──┤────────>│   Compute       │──────┤    ├──────────────────┤
 │ Files / CSVs │  │  Load   │   Storage       │ Query│    │ Data Science     │
 │ APIs         │──┤         │                 │      │    │ (Notebooks, ML)  │
 │ Streaming    │──┘         │                 │      ├───>├──────────────────┤
 └──────────────┘            └─────────────────┘      │    │ Applications     │
                                                      └───>│ Data Shares      │
                                                           └──────────────────┘
```

---

## Core Terminology

Before you start the labs, familiarize yourself with these terms. You will encounter every one of them during the workshop.

| Term | Definition |
|------|-----------|
| **Virtual Warehouse** | A named compute cluster that executes queries and DML. Warehouses come in sizes (XS to 6XL) and can be started, stopped, and resized independently. |
| **Database** | A logical container for schemas, tables, views, and other objects. Similar to a database in any relational system. |
| **Schema** | A logical grouping of objects within a database. Every table, view, and function lives inside a schema. |
| **Stage** | A location (internal or external) where data files are placed before loading into tables. Think of it as a landing zone. |
| **Role** | A named collection of privileges. Users are granted roles, and roles determine what objects they can access. Snowflake uses role-based access control (RBAC). |
| **Credit** | The unit of measure for compute usage. One credit corresponds to one node of compute running for one hour. Larger warehouses consume more credits per hour. |
| **Micro-partition** | The physical unit of storage in Snowflake. Each micro-partition is a compressed, columnar, immutable file containing 50-500 MB of uncompressed data. |
| **Snowsight** | Snowflake's web-based user interface. You will use Snowsight for all labs in this workshop. |

---

## Editions at a Glance

Snowflake offers multiple editions. Each higher edition includes everything in the one below it.

| Capability | Standard | Enterprise | Business Critical |
|-----------|----------|------------|-------------------|
| Full SQL engine and all core features | Yes | Yes | Yes |
| Multi-cluster warehouses | -- | Yes | Yes |
| Time Travel (up to 90 days) | 1 day | Up to 90 days | Up to 90 days |
| Materialized views | -- | Yes | Yes |
| Column-level security | -- | Yes | Yes |
| Search optimization | -- | Yes | Yes |
| Enhanced security (HIPAA, PCI DSS) | -- | -- | Yes |
| Database failover and failback | -- | -- | Yes |
| AWS PrivateLink / Azure Private Link | -- | -- | Yes |

For this workshop, an **Enterprise** trial account is recommended so you can explore all features.

---

## How This Workshop Is Organized

The workshop is divided into three modules that progressively build your skills:

- **Module 1: Core Essentials (Labs 01-05)** -- Navigate Snowsight, create warehouses, build objects, load data, and write queries. These labs establish the foundation.
- **Module 2: Data Engineering (Labs 06-10)** -- Set up access control, use Time Travel and cloning, build CDC pipelines with Streams and Tasks, and configure continuous loading with Snowpipe.
- **Module 3: Advanced Features (Labs 11-15)** -- Write stored procedures and UDFs, share data across accounts, create dynamic tables, tune performance, and tie everything together in a capstone project.

Each lab has a `guide.md` with step-by-step instructions and a `.sql` script you run in Snowsight.

---

## Next Steps

- **Next reading:** [Traditional Databases vs Snowflake](02-traditional-vs-snowflake.md) -- understand how Snowflake differs from what you already know.
- **Ready to start?** Jump to [Lab 01 -- Getting Started](lab-01-getting-started/guide.md) if you want to dive in immediately.
