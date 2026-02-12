# Snowflake Architecture

## Pre-Workshop Reading | ~10 minutes

Snowflake's architecture is what makes it fundamentally different from traditional databases. Understanding these three layers will help you make better decisions throughout the workshop and beyond.

---

## The Big Picture

Snowflake is built on three independent layers. Each layer scales on its own, without affecting the others.

```
 ┌─────────────────────────────────────────────────────────────────────┐
 │                        CLOUD SERVICES                              │
 │   Authentication, query optimization, metadata management,        │
 │   transaction control, result cache, infrastructure management     │
 └──────────────────────────────┬──────────────────────────────────────┘
                                │
 ┌──────────────────────────────▼──────────────────────────────────────┐
 │                     QUERY PROCESSING (COMPUTE)                     │
 │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
 │  │ Warehouse A  │  │ Warehouse B  │  │ Warehouse C  │   ...        │
 │  │  (ETL)       │  │  (BI)        │  │  (Ad hoc)    │              │
 │  └──────────────┘  └──────────────┘  └──────────────┘              │
 └──────────────────────────────┬──────────────────────────────────────┘
                                │
 ┌──────────────────────────────▼──────────────────────────────────────┐
 │                        STORAGE                                     │
 │   Centralized, managed cloud object storage                        │
 │   (micro-partitions, compressed, columnar, encrypted)              │
 └─────────────────────────────────────────────────────────────────────┘
```

**Key insight:** Because these layers are independent, you can scale compute without changing storage, add warehouses without moving data, and store petabytes without provisioning a single disk.

---

## Layer 1: Cloud Services

The cloud services layer is the brain of Snowflake. It coordinates everything that happens in the platform, but you rarely interact with it directly.

### Responsibilities

- **Authentication and access control** -- validates logins, enforces MFA, checks role-based permissions on every operation.
- **Query compilation and optimization** -- parses SQL, generates execution plans, applies cost-based optimization, and decides which micro-partitions to read.
- **Metadata management** -- maintains a catalog of every database, schema, table, column, micro-partition, and their statistics. This metadata powers pruning.
- **Transaction management** -- coordinates ACID transactions across concurrent operations.
- **Result cache** -- stores the results of queries for 24 hours. If you run the same query on unchanged data, Snowflake returns the cached result instantly -- no warehouse needed.
- **Infrastructure management** -- provisions and deprovisions compute resources, manages software updates, and handles availability zone distribution.

### Key Facts

| Property | Detail |
|----------|--------|
| Always running | Yes -- cloud services are always on, even when all warehouses are suspended |
| Billed separately? | Only if cloud services consumption exceeds 10% of daily warehouse credits |
| User-configurable? | No -- fully managed by Snowflake |
| Shared across warehouses? | Yes -- all warehouses use the same cloud services layer |

### Where You See This in the Workshop

- **Lab 01** -- when you log in and navigate Snowsight, cloud services authenticates you and serves the UI.
- **Lab 06** -- when you create roles and grant privileges, cloud services enforces access control.
- **Lab 14** -- when you examine the query profile, you see the optimizer's execution plan.

---

## Layer 2: Query Processing (Compute)

The compute layer is where queries actually execute. It consists of one or more **virtual warehouses** -- independent compute clusters that you create and manage.

### How Virtual Warehouses Work

A virtual warehouse is a named cluster of compute nodes provisioned from the cloud provider. When you submit a query, the warehouse assigned to your session fetches the required micro-partitions from storage, processes them in memory, and returns the results.

Each warehouse is **completely independent**. Warehouse A cannot see or affect Warehouse B. They share data through the storage layer, but their compute resources are isolated.

### Key Properties

| Property | Detail |
|----------|--------|
| Start time | Seconds (typically under 5 seconds) |
| Auto-suspend | Configurable (default: 10 minutes of idle time) |
| Auto-resume | Yes -- starts automatically when a query arrives |
| Multi-cluster | Enterprise edition and above -- automatically adds clusters under concurrency pressure |
| Resizable | Yes -- change size while running (new size takes effect on next query) |

### Warehouse Sizing

Each size doubles the compute resources (and credit consumption) of the previous size.

| Size | Credits/Hour | Typical Use Case |
|------|-------------|-----------------|
| XS (X-Small) | 1 | Development, testing, light queries |
| S (Small) | 2 | Small-to-medium analytics workloads |
| M (Medium) | 4 | Medium analytics, moderate ETL |
| L (Large) | 8 | Large analytics, heavy ETL |
| XL (X-Large) | 16 | Data-intensive processing |
| 2XL | 32 | Large-scale data processing |
| 3XL | 64 | Very large-scale processing |
| 4XL | 128 | Massive workloads |
| 5XL | 256 | Extreme-scale processing |
| 6XL | 512 | Maximum compute power |

**Rule of thumb:** Start with XS or S. Monitor the query profile. Scale up only if queries are slow because of compute, not because of inefficient SQL.

### Where You See This in the Workshop

- **Lab 02** -- you create, resize, suspend, and resume warehouses hands-on.
- **Lab 14** -- you analyze how warehouse size affects query performance.

---

## Layer 3: Storage

The storage layer holds all data in Snowflake. You never interact with it directly -- Snowflake manages every aspect of how data is written, organized, compressed, and retrieved.

### Micro-Partitions

The fundamental unit of storage in Snowflake is the **micro-partition**. When you load data into a table, Snowflake automatically divides it into micro-partitions.

```
  TABLE: ORDERS (millions of rows)
  ┌──────────────────────────────────────────────────────────────────┐
  │                                                                  │
  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
  │  │ Partition 1  │  │ Partition 2  │  │ Partition 3  │  ...      │
  │  │              │  │              │  │              │           │
  │  │ 50-500 MB    │  │ 50-500 MB    │  │ 50-500 MB    │           │
  │  │ (uncompressed│  │ (uncompressed│  │ (uncompressed│           │
  │  │  size)       │  │  size)       │  │  size)       │           │
  │  └──────────────┘  └──────────────┘  └──────────────┘           │
  │                                                                  │
  │  METADATA (stored in cloud services layer):                      │
  │  ┌──────────────────────────────────────────────────────────┐    │
  │  │  Partition 1:  order_date min=2024-01-01, max=2024-01-15│    │
  │  │                customer_id min=1000, max=5000            │    │
  │  │                distinct values, null count, ...          │    │
  │  ├──────────────────────────────────────────────────────────┤    │
  │  │  Partition 2:  order_date min=2024-01-10, max=2024-01-31│    │
  │  │                customer_id min=3000, max=9000            │    │
  │  │                distinct values, null count, ...          │    │
  │  ├──────────────────────────────────────────────────────────┤    │
  │  │  Partition 3:  order_date min=2024-02-01, max=2024-02-20│    │
  │  │                customer_id min=1500, max=7000            │    │
  │  │                distinct values, null count, ...          │    │
  │  └──────────────────────────────────────────────────────────┘    │
  └──────────────────────────────────────────────────────────────────┘
```

### Key Properties

- **Size** -- each micro-partition holds 50-500 MB of uncompressed data (much smaller after compression).
- **Columnar** -- data is stored column by column, making analytical queries fast because only the needed columns are read.
- **Compressed** -- Snowflake applies automatic compression, typically achieving 3-5x reduction.
- **Encrypted** -- all micro-partitions are encrypted at rest using AES-256.
- **Immutable** -- micro-partitions are never updated in place. INSERT, UPDATE, and DELETE operations create new partitions and mark old ones for removal.
- **Automatic** -- you do not create, manage, or even see micro-partitions. Snowflake handles all of it.

---

## How Pruning Replaces Indexes

In a traditional database, you create indexes to avoid full table scans. In Snowflake, **pruning** serves the same purpose -- but without any manual work.

Here is how it works with a concrete example:

```sql
SELECT order_id, amount
FROM orders
WHERE order_date = '2024-02-10';
```

**Step 1:** Snowflake checks the micro-partition metadata in the cloud services layer.

**Step 2:** For each partition, it compares the WHERE clause against the stored min/max values for `order_date`:

```
  Partition 1:  order_date min=2024-01-01, max=2024-01-15
                2024-02-10 is OUTSIDE this range --> SKIP

  Partition 2:  order_date min=2024-01-10, max=2024-01-31
                2024-02-10 is OUTSIDE this range --> SKIP

  Partition 3:  order_date min=2024-02-01, max=2024-02-20
                2024-02-10 is INSIDE this range  --> SCAN
```

**Step 3:** The warehouse reads **only Partition 3** from storage. Partitions 1 and 2 are never touched.

**Result:** Out of 3 partitions, only 1 was scanned. In a real table with thousands of partitions, pruning can skip 99%+ of the data -- all without a single index.

For tables where natural ordering does not align well with common query patterns, you can define a **clustering key** to hint Snowflake on how to organize data across micro-partitions.

### Where You See This in the Workshop

- **Lab 14** -- you examine the query profile and see how many partitions were scanned vs. pruned.

---

## Query Lifecycle

When you submit a query in Snowsight, here is what happens across the three layers:

```
  You submit a query
        │
        ▼
  ┌─────────────────────────────────────────────────┐
  │  1. CLOUD SERVICES receives the query           │
  │     - Parses and validates SQL                   │
  │     - Checks permissions (role/privileges)       │
  │     - Checks result cache (24-hour window)       │
  │       → If cache hit: return result immediately  │
  └──────────────────────┬──────────────────────────┘
                         │ (cache miss)
                         ▼
  ┌─────────────────────────────────────────────────┐
  │  2. CLOUD SERVICES creates execution plan        │
  │     - Cost-based optimizer builds the plan       │
  │     - Pruning: identifies which partitions       │
  │       to scan and which to skip                  │
  └──────────────────────┬──────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────┐
  │  3. WAREHOUSE executes the plan                  │
  │     - Fetches required micro-partitions          │
  │       from storage                               │
  │     - Processes data in parallel across nodes    │
  │     - Joins, filters, aggregates in memory       │
  └──────────────────────┬──────────────────────────┘
                         │
                         ▼
  ┌─────────────────────────────────────────────────┐
  │  4. RESULTS returned to you                      │
  │     - Query result cached for 24 hours           │
  │     - Warehouse auto-suspends if idle            │
  └─────────────────────────────────────────────────┘
```

**Notice:** If the result cache has a hit in step 1, the warehouse is never started. This means cached queries are free -- no compute credits consumed.

---

## Architecture-to-Labs Mapping

As you work through the labs, you will interact with every layer of the architecture. This table shows where each concept appears.

| Architecture Feature | Lab(s) | What You Do |
|---------------------|--------|-------------|
| Snowsight (Cloud Services UI) | Lab 01 | Navigate the interface, run queries |
| Virtual Warehouses | Lab 02 | Create, resize, suspend, resume warehouses |
| Databases, Schemas, Tables | Lab 03 | Create and organize database objects |
| Data Loading (Storage) | Lab 04 | Load data into micro-partitions via COPY INTO |
| SQL Query Processing | Lab 05 | Write queries that the compute layer executes |
| Role-Based Access Control | Lab 06 | Configure roles and privileges (cloud services) |
| Time Travel (Storage) | Lab 07 | Query historical data via retained micro-partitions |
| Zero-Copy Cloning (Metadata) | Lab 08 | Clone objects using metadata pointers |
| Streams & Tasks (Cloud Services) | Lab 09 | Automate change tracking and task scheduling |
| Snowpipe (Cloud Services) | Lab 10 | Continuous loading orchestrated by cloud services |
| Procedures & UDFs (Compute) | Lab 11 | Execute procedural logic on warehouses |
| Data Sharing (Cloud Services) | Lab 12 | Share data without moving it |
| Dynamic Tables (Compute + Cloud Services) | Lab 13 | Declarative pipelines managed by both layers |
| Performance Tuning (All Layers) | Lab 14 | Analyze query profiles, pruning, caching |
| Capstone (All Layers) | Lab 15 | End-to-end project spanning all three layers |

---

## Key Takeaways

1. **Three independent layers** -- Cloud Services, Compute, and Storage scale and operate independently of each other.
2. **Compute is elastic and isolated** -- warehouses start in seconds, run your workload, and can be suspended when idle. Different workloads get different warehouses.
3. **Storage is managed and unlimited** -- data is automatically divided into micro-partitions, compressed, encrypted, and stored in cloud object storage.
4. **Pruning replaces indexes** -- micro-partition metadata allows Snowflake to skip irrelevant data automatically, without manual index creation.
5. **Result caching is free** -- identical queries on unchanged data return instantly from cache with zero compute cost.
6. **You manage the work, not the infrastructure** -- your job is to write good SQL, organize your data, and right-size your warehouses. Snowflake handles everything else.

---

## Next Steps

- **Ready to start?** Jump to [Lab 01 -- Getting Started](lab-01-getting-started/guide.md) to begin hands-on work in Snowsight.
- **Review:** [Introduction to Snowflake](01-introduction.md) | [Traditional Databases vs Snowflake](02-traditional-vs-snowflake.md)
