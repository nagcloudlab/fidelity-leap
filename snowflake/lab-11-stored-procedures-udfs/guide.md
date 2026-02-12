# Lab 11: Stored Procedures & User-Defined Functions (UDFs)

## Objective

Learn to create reusable logic with **Stored Procedures** and **User-Defined Functions (UDFs)** in Snowflake. By the end of this lab you will be able to write SQL and JavaScript stored procedures, build scalar and table-valued UDFs, and understand when to use each construct.

## Duration

**35 minutes**

## Prerequisites

- Completion of Labs 1-5 (basic Snowflake navigation, warehouse usage, and querying)
- `WORKSHOP_DB` database and `PUBLIC` schema available
- A running warehouse (e.g., `WORKSHOP_WH`)

## Key Concepts

| Concept | Description |
|---|---|
| **Stored Procedure** | A named block of procedural logic that can execute SQL statements, perform control flow, and modify data. Called with `CALL`. |
| **User-Defined Function (UDF)** | A named function that accepts input parameters and returns a value. Can be used inline inside `SELECT` and other SQL statements. |
| **Scalar UDF** | A UDF that returns a single value for each input row. |
| **Table UDF (UDTF)** | A UDF that returns a set of rows, used in the `FROM` clause with `TABLE()`. |
| **Snowflake Scripting** | Snowflake's procedural SQL extension supporting variables (`LET`), conditionals (`IF`/`ELSE`), loops (`FOR`, `WHILE`), and exception handling inside `BEGIN...END` blocks. |
| **JavaScript Language** | Stored procedures and UDFs can be written in JavaScript for complex string manipulation, JSON processing, or algorithmic logic. |
| **RETURNS** | Clause that declares the data type a procedure or function will return. |
| **LANGUAGE** | Clause that specifies the language of the handler body (`SQL`, `JAVASCRIPT`, `PYTHON`, `JAVA`, `SCALA`). |
| **CALL** | Statement used to execute a stored procedure. |
| **Caller's Rights** | The procedure runs with the privileges of the user who calls it (`EXECUTE AS CALLER`). |
| **Owner's Rights** | The procedure runs with the privileges of the role that owns it (`EXECUTE AS OWNER`). This is the default. |
| **Overloading** | Creating multiple functions or procedures with the same name but different parameter signatures. |

## Stored Procedures vs UDFs -- Comparison

| Feature | Stored Procedure | UDF |
|---|---|---|
| **Invocation** | `CALL my_proc(...)` | Used inline: `SELECT my_func(...)` |
| **Return value** | Single value (or nothing) | Scalar value or table (UDTF) |
| **Side effects** | Can execute DML/DDL (INSERT, CREATE, DROP, etc.) | Must be side-effect-free; read-only |
| **Use in SQL expressions** | No -- cannot appear in SELECT, WHERE, etc. | Yes -- used anywhere an expression is valid |
| **Transaction control** | Can commit/rollback | No |
| **Primary purpose** | Automation, orchestration, administrative tasks | Data transformation, calculation, formatting |
| **Languages** | SQL (Snowflake Scripting), JavaScript, Python, Java, Scala | SQL, JavaScript, Python, Java, Scala |

**Rule of thumb:** If you need to *read and transform* data, use a UDF. If you need to *modify* data or run DDL, use a stored procedure.

## Step-by-Step Instructions

### Part 1 -- Stored Procedures (15 minutes)

1. **Open a new SQL worksheet** in Snowsight and set context to `WORKSHOP_DB.PUBLIC` with warehouse `WORKSHOP_WH`.
2. **Create sample data** -- Run the setup section at the top of `lab-11.sql` to create the tables used throughout this lab.
3. **Simple SQL stored procedure** -- Create `cleanup_old_orders` which deletes orders older than a given number of days. Notice the `RETURNS`, `LANGUAGE SQL`, and `EXECUTE AS CALLER` clauses.
4. **Call the procedure** -- Use `CALL cleanup_old_orders(365);` and observe the return message.
5. **Stored procedure with Snowflake Scripting** -- Study the `generate_monthly_report` procedure. It uses `DECLARE`, `LET`, `IF/ELSE`, `FOR`, and `RESULTSET` to build control-flow logic entirely in SQL.
6. **JavaScript stored procedure** -- Review `process_json_data`. JavaScript procedures are useful when you need string manipulation, regex, or JSON parsing that goes beyond SQL's built-in functions.
7. **Explore metadata** -- Run `SHOW PROCEDURES IN SCHEMA WORKSHOP_DB.PUBLIC;` and `DESCRIBE PROCEDURE cleanup_old_orders(FLOAT);` to inspect what you created.

### Part 2 -- User-Defined Functions (15 minutes)

8. **Scalar SQL UDF** -- Create `calculate_discount` which returns a discounted price. Use it directly in a `SELECT` statement.
9. **Email masking UDF** -- Create `mask_email` to partially obscure email addresses -- a common compliance requirement.
10. **JavaScript UDF** -- Create `title_case` to convert strings to title case using JavaScript's string methods.
11. **Table UDF (UDTF)** -- Create `generate_date_series` which returns a table of dates between two endpoints. Use it with `TABLE()` in a `FROM` clause.
12. **Function overloading** -- Create two versions of `format_name` with different parameter counts to see how Snowflake resolves overloaded signatures.
13. **Use UDFs in queries** -- Combine your UDFs in real queries against the sample tables.

### Part 3 -- Practical Examples & Review (5 minutes)

14. **Data quality check procedure** -- Run `check_data_quality` to see a procedure that validates table contents and returns a JSON report.
15. **Inspect functions and procedures** -- Use `SHOW FUNCTIONS` and `SHOW PROCEDURES` to list everything you created.
16. **Cleanup** -- Run the cleanup section to drop all objects created during this lab.

## Best Practices

1. **Choose the right tool.** Use UDFs for calculations and transformations inside queries. Use stored procedures for orchestration, DML, and DDL operations.
2. **Prefer SQL over JavaScript** when possible. SQL-based procedures and UDFs are generally faster because Snowflake can optimize them within its query engine.
3. **Use Snowflake Scripting for procedural SQL.** The `BEGIN...END` block with `LET`, `IF`, `FOR`, and exception handling keeps logic in pure SQL without switching to another language.
4. **Keep functions deterministic** when possible. Mark functions as `IMMUTABLE` if they always return the same output for the same input -- this allows Snowflake to cache results.
5. **Use caller's rights carefully.** `EXECUTE AS CALLER` gives the procedure the caller's privileges, which is flexible but means results depend on who runs it. `EXECUTE AS OWNER` (the default) is more predictable.
6. **Name clearly and document.** Use `COMMENT` on every procedure and function so other users can understand its purpose via `SHOW FUNCTIONS` or `DESCRIBE FUNCTION`.
7. **Avoid side effects in UDFs.** UDFs must not modify data. If you need to write data, use a stored procedure instead.
8. **Handle NULLs explicitly.** Always consider what your function should return when it receives NULL input. Use `NVL`, `COALESCE`, or early-return logic.
9. **Test with edge cases.** Test UDFs with empty strings, NULLs, negative numbers, boundary dates, and large inputs before deploying to production.
10. **Use overloading sparingly.** Overloaded functions are convenient but can confuse users. Make sure each overload has a clearly distinct purpose.

## Review Questions

1. What is the main difference between a stored procedure and a UDF in Snowflake? When would you choose one over the other?

2. Can you use a stored procedure inside a `SELECT` statement? Why or why not?

3. What does `EXECUTE AS CALLER` mean, and how does it differ from the default `EXECUTE AS OWNER`?

4. Explain what a Table UDF (UDTF) is and how its usage in a query differs from a scalar UDF.

5. You have two functions both named `format_name` -- one accepts one argument and the other accepts two. How does Snowflake decide which one to execute?

6. Why might you choose to write a JavaScript UDF instead of a SQL UDF?

7. In a Snowflake Scripting stored procedure, what is the purpose of the `LET` keyword and the `RESULTSET` data type?

8. A colleague wrote a UDF that inserts rows into a logging table every time it is called. What problem will they encounter?

## Next Steps

Continue to **Lab 12: Data Sharing** to learn how Snowflake enables secure sharing of data across accounts without copying.
