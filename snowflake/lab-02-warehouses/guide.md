# Lab 02: Virtual Warehouses

## Objective
Learn how to create, configure, resize, suspend, and resume virtual warehouses -- the compute engines that power all queries in Snowflake.

## Duration: 30 minutes

---

## Key Concepts

- **Virtual Warehouse** -- A cluster of compute resources (CPU, memory, temp storage) that executes queries
- **T-shirt Sizing** -- Warehouses come in sizes: X-Small, Small, Medium, Large, X-Large, etc. Each size doubles the compute (and cost)
- **Auto-Suspend** -- Automatically shuts down the warehouse after a period of inactivity (saves credits)
- **Auto-Resume** -- Automatically starts the warehouse when a query is submitted
- **Multi-Cluster Warehouses** -- Scale out by adding clusters to handle concurrent query load
- **Credit Consumption** -- Each warehouse size has a per-second billing rate (X-Small = 1 credit/hour)

---

## Warehouse Sizes & Credits

| Size | Credits/Hour | Nodes |
|------|-------------|-------|
| X-Small | 1 | 1 |
| Small | 2 | 2 |
| Medium | 4 | 4 |
| Large | 8 | 8 |
| X-Large | 16 | 16 |
| 2X-Large | 32 | 32 |

---

## Step-by-Step Instructions

### Step 1: Explore existing warehouses
Run SHOW WAREHOUSES to see what already exists in your account.

### Step 2: Create warehouses of different sizes
Create X-Small and Small warehouses with proper auto-suspend settings.

### Step 3: Test warehouse performance
Run the same query on different warehouse sizes and compare execution times.

### Step 4: Resize a running warehouse
Scale a warehouse up and down without restarting it.

### Step 5: Configure multi-cluster warehouse
Create a warehouse that scales out to handle concurrent users.

### Step 6: Monitor warehouse usage
Query system views to see credit consumption and query load.

### Step 7: Clean up
Suspend or drop warehouses you no longer need.

---

## Best Practices
- Set AUTO_SUSPEND to 60-300 seconds (1-5 minutes) for interactive use
- Always enable AUTO_RESUME
- Start with X-Small and scale up only when needed
- Use separate warehouses for different workloads (ETL vs. BI vs. ad-hoc)
- Monitor credit usage regularly

---

## Review Questions
1. What happens to running queries when you resize a warehouse?
2. How does multi-cluster warehousing differ from scaling up?
3. What is the minimum billing increment for a warehouse?
