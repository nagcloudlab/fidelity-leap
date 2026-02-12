# Lab 01: Getting Started with Snowflake

## Objective
Learn to navigate the Snowflake web interface (Snowsight), create your first worksheet, and run basic commands to explore your account.

## Duration: 20 minutes

---

## Key Concepts

- **Snowsight** -- Snowflake's modern web UI for querying, visualizing, and managing data
- **Worksheet** -- An interactive SQL editor within Snowsight
- **Context** -- The active role, warehouse, database, and schema for your session
- **Information Schema** -- System views that describe all objects in your account

---

## Step-by-Step Instructions

### Step 1: Log In to Snowflake
1. Open your browser and navigate to your Snowflake account URL
2. Enter your username and password
3. You will land on the **Snowsight** home page

### Step 2: Explore the Navigation
Take a moment to explore the left sidebar:
- **Worksheets** -- Where you write and run SQL
- **Dashboards** -- Build visual dashboards
- **Data** -- Browse databases, schemas, and tables
- **Marketplace** -- Access shared datasets
- **Activity** -- View query history and task runs
- **Admin** -- Manage warehouses, users, and account settings

### Step 3: Create Your First Worksheet
1. Click **Worksheets** in the left sidebar
2. Click the **+ (New Worksheet)** button
3. Name it `Lab 01 - Getting Started`

### Step 4: Set Your Context
In the worksheet, set your working context using the dropdown menus at the top, or run the SQL commands in the script.

### Step 5: Run the Lab SQL Script
Open `lab-01.sql` and execute each statement one at a time:
- Highlight a statement
- Press **Ctrl+Enter** (or **Cmd+Enter** on Mac)
- Review the results in the bottom panel

### Step 6: Explore the Results
- Click on different result tabs
- Try the **Chart** button to visualize results
- Check the **Query Profile** to see execution details

---

## What You Will Learn
- How to navigate Snowsight
- How to create and manage worksheets
- How to set session context (role, warehouse, database, schema)
- How to explore your account using system commands
- How to use SHOW and DESCRIBE commands

---

## Review Questions
1. What is the difference between ACCOUNTADMIN and SYSADMIN roles?
2. How many warehouses exist in your account by default?
3. What information does `SELECT CURRENT_VERSION()` return?
