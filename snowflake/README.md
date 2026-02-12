# Snowflake Hands-On Workshop

## Full-Day Training | Beginner to Advanced

---

## Workshop Overview

This workshop provides **15 hands-on labs** that take you from Snowflake fundamentals to advanced features. Each lab includes a **step-by-step guide** and a **ready-to-run SQL script**.

**Duration:** ~8 hours (full day)
**Level:** Beginner-friendly, progressing to advanced topics
**Format:** Instructor-led with hands-on lab exercises

---

## Prerequisites

- A Snowflake account (Trial account works: https://signup.snowflake.com/)
- Web browser (Chrome, Firefox, or Edge recommended)
- Basic SQL knowledge (SELECT, INSERT, UPDATE, DELETE)
- No local software installation required -- everything runs in Snowflake's web UI

---

## Pre-Workshop Reading

Before diving into the labs, review these guides to build a solid foundation. They are designed for anyone with SQL experience who is new to Snowflake.

| # | Guide | Reading Time | What You Learn |
|---|-------|-------------|----------------|
| 1 | [Introduction to Snowflake](01-introduction.md) | ~8 min | What Snowflake is, why it exists, core terminology |
| 2 | [Traditional Databases vs Snowflake](02-traditional-vs-snowflake.md) | ~10 min | How Snowflake differs from traditional RDBMS |
| 3 | [Snowflake Architecture](03-snowflake-architecture.md) | ~10 min | Three-layer architecture, micro-partitions, pruning, query lifecycle |

---

## Workshop Agenda

### Module 1: Core Essentials (Labs 01-05) -- ~3 hours

| Lab | Title | Duration | Description |
|-----|-------|----------|-------------|
| 01 | Getting Started | 20 min | Snowflake UI navigation, account setup, worksheet basics |
| 02 | Virtual Warehouses | 30 min | Create, configure, resize, suspend/resume warehouses |
| 03 | Databases, Schemas & Tables | 40 min | DDL operations, data types, constraints, views |
| 04 | Loading Data | 45 min | Stages, file formats, COPY INTO, bulk loading |
| 05 | Querying Data | 45 min | Snowflake SQL features, CTEs, window functions, FLATTEN |

### Module 2: Data Engineering (Labs 06-10) -- ~3 hours

| Lab | Title | Duration | Description |
|-----|-------|----------|-------------|
| 06 | Roles & Access Control | 30 min | RBAC, custom roles, privileges, role hierarchy |
| 07 | Time Travel & Fail-safe | 30 min | Query history data, UNDROP, AT/BEFORE clauses |
| 08 | Zero-Copy Cloning | 25 min | Clone databases, schemas, tables with zero storage cost |
| 09 | Streams & Tasks | 45 min | Change data capture, task scheduling, task trees |
| 10 | Snowpipe | 30 min | Continuous data loading, pipe management, monitoring |

### Module 3: Advanced Features (Labs 11-15) -- ~2 hours

| Lab | Title | Duration | Description |
|-----|-------|----------|-------------|
| 11 | Stored Procedures & UDFs | 35 min | JavaScript & SQL procedures, scalar/table UDFs |
| 12 | Data Sharing | 25 min | Secure shares, reader accounts, listings |
| 13 | Dynamic Tables & Materialized Views | 30 min | Declarative pipelines, auto-refresh, materialized views |
| 14 | Performance Tuning | 30 min | Query profiling, clustering, caching, optimization tips |
| 15 | Capstone Project | 45 min | End-to-end mini project combining all concepts |

---

## Folder Structure

```
snowflake-workshop/
├── README.md                          # This file
├── 01-introduction.md                 # Pre-workshop: What is Snowflake?
├── 02-traditional-vs-snowflake.md     # Pre-workshop: Traditional DB vs Snowflake
├── 03-snowflake-architecture.md       # Pre-workshop: Three-layer architecture
├── setup/
│   ├── 00_workshop_setup.sql          # Master setup script
│   └── 00_workshop_cleanup.sql        # Master cleanup script
├── data/
│   ├── customers.csv                  # Sample customer data
│   ├── orders.csv                     # Sample order data
│   ├── products.csv                   # Sample product data
│   └── events.json                    # Sample JSON event data
├── lab-01-getting-started/
│   ├── guide.md                       # Step-by-step instructions
│   └── lab-01.sql                     # SQL script
├── lab-02-warehouses/
│   ├── guide.md
│   └── lab-02.sql
│   ... (same pattern for all labs)
└── lab-15-capstone-project/
    ├── guide.md
    └── lab-15.sql
```

---

## How to Use This Workshop

1. **Read the Pre-Workshop Guides:** Start with the three guides above to understand Snowflake's architecture and terminology
2. **Run the Setup:** Run `setup/00_workshop_setup.sql` to create the workshop database and load sample data
3. **Follow the Labs in Order:** Each lab builds on concepts from previous labs
4. **Read the Guide First:** Open `guide.md` in each lab folder for context and instructions
5. **Run the SQL:** Open `lab-XX.sql` in a Snowflake Worksheet and execute step by step
6. **Cleanup:** Run `setup/00_workshop_cleanup.sql` when done to remove workshop objects

---

## Snowflake Account Setup (For Trial Accounts)

1. Go to https://signup.snowflake.com/
2. Choose **Enterprise** edition (recommended for all features)
3. Select a cloud provider (AWS, Azure, or GCP) and region
4. Complete registration -- you get **$400 in free credits** (30-day trial)
5. Log in and you are ready to start Lab 01!

---

## Tips for Participants

- **Run statements one at a time** -- highlight a statement and press Ctrl+Enter (Cmd+Enter on Mac)
- **Read the comments** in SQL scripts -- they explain what each step does
- **Experiment!** Modify queries, try different values, break things and fix them
- **Use SHOW and DESCRIBE** commands to explore objects
- **Check the Query Profile** tab to understand how queries execute
