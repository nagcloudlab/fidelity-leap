# Lab 06: Roles & Access Control

## Objective

Understand Snowflake's **Role-Based Access Control (RBAC)** model and implement a
real-world access control hierarchy. By the end of this lab you will be able to:

- Explain the purpose of each system-defined role.
- Design and build a custom role hierarchy.
- Grant and revoke privileges at the database, schema, and table levels.
- Verify effective permissions using `SHOW GRANTS`.
- Apply the principle of least privilege in practice.

## Duration

**30 minutes**

## Prerequisites

| Requirement | Detail |
|---|---|
| Snowflake account | Trial or paid (any cloud / region) |
| Role | You must be able to switch to **ACCOUNTADMIN** |
| Prior labs | Familiarity with databases, schemas, and tables (Labs 01-05) |

## Key Concepts

### Role-Based Access Control (RBAC)

Snowflake controls every action through **roles**. A role is a named collection of
privileges. Users never receive privileges directly; instead, privileges are granted
to roles, and roles are granted to users (or to other roles).

```
Privilege  -->  Role  -->  User
```

### System-Defined Roles

Snowflake ships with five built-in roles. They form a fixed hierarchy that cannot be
removed.

| Role | Purpose |
|---|---|
| **ACCOUNTADMIN** | Top-level role. Combines SYSADMIN and SECURITYADMIN. Use sparingly. |
| **SECURITYADMIN** | Manages users, roles, and grants. Owns the USERADMIN role. |
| **USERADMIN** | Can create and manage users and roles (subset of SECURITYADMIN). |
| **SYSADMIN** | Creates and manages databases, warehouses, and other objects. All custom roles should eventually roll up to SYSADMIN. |
| **PUBLIC** | Automatically granted to every user. Use for truly public objects only. |

### Role Hierarchy Diagram

```
            ACCOUNTADMIN
           /            \
    SYSADMIN          SECURITYADMIN
        |                  |
  (custom roles)      USERADMIN
        |                  |
      ...               PUBLIC
        |
      PUBLIC
```

- A **parent role** automatically inherits every privilege of its **child roles**.
- Custom roles should be granted to **SYSADMIN** (directly or indirectly) so that
  ACCOUNTADMIN retains visibility over all objects.

### Privileges

Privileges control what a role can do. Common privilege keywords:

| Privilege | Applies To | Description |
|---|---|---|
| `USAGE` | Database, Schema, Warehouse | Allows the role to "see" and use the object |
| `SELECT` | Table, View | Read rows |
| `INSERT` | Table | Add rows |
| `UPDATE` | Table | Modify rows |
| `DELETE` | Table | Remove rows |
| `CREATE TABLE` | Schema | Create new tables in a schema |
| `CREATE VIEW` | Schema | Create new views in a schema |
| `CREATE SCHEMA` | Database | Create new schemas in a database |
| `OWNERSHIP` | Any | Full control, including the ability to grant to others |

### GRANT and REVOKE

```sql
-- Give a privilege
GRANT <privilege> ON <object_type> <object_name> TO ROLE <role_name>;

-- Take a privilege away
REVOKE <privilege> ON <object_type> <object_name> FROM ROLE <role_name>;

-- Give a role to a user
GRANT ROLE <role_name> TO USER <user_name>;

-- Build hierarchy: give a child role to a parent role
GRANT ROLE <child_role> TO ROLE <parent_role>;
```

## Lab Steps

Open the companion file **lab-06.sql** in a Snowflake worksheet and work through each
section in order. A summary of the steps is below.

### Step 1 -- Explore System Roles

Switch to ACCOUNTADMIN and inspect the built-in roles and their grants. Understand
what each system role owns before creating anything new.

### Step 2 -- Examine the Existing Role Hierarchy

Use `SHOW GRANTS` to see how system roles relate to each other. Note that
ACCOUNTADMIN inherits from both SYSADMIN and SECURITYADMIN.

### Step 3 -- Create Custom Roles

Create four project-specific roles that map to common job functions:

| Custom Role | Intended For |
|---|---|
| `WORKSHOP_READER` | Business stakeholders who only need to view data |
| `WORKSHOP_ANALYST` | Analysts who query and create views |
| `WORKSHOP_DEVELOPER` | Developers who create and modify tables |
| `WORKSHOP_ADMIN` | Project lead with full database management |

### Step 4 -- Build the Custom Role Hierarchy

Chain the custom roles so that each higher role inherits the privileges of the roles
below it, and the top custom role rolls up to SYSADMIN.

```
SYSADMIN
   |
WORKSHOP_ADMIN
   |
WORKSHOP_DEVELOPER
   |
WORKSHOP_ANALYST
   |
WORKSHOP_READER
   |
 PUBLIC
```

### Step 5 -- Grant Privileges

Grant an increasing set of privileges to each role:

- **WORKSHOP_READER** -- USAGE on database/schema, SELECT on tables.
- **WORKSHOP_ANALYST** -- Everything READER has (via hierarchy) plus CREATE VIEW.
- **WORKSHOP_DEVELOPER** -- Everything ANALYST has plus INSERT, UPDATE, DELETE,
  CREATE TABLE.
- **WORKSHOP_ADMIN** -- Everything DEVELOPER has plus CREATE SCHEMA, and OWNERSHIP
  of the database.

### Step 6 -- Create Test Users and Assign Roles

Create sample users and assign one custom role to each. Then switch roles with
`USE ROLE` to prove that privilege boundaries work as expected.

### Step 7 -- Verify, Revoke, and Clean Up

- Use `SHOW GRANTS ON ...` and `SHOW GRANTS TO ROLE ...` to audit permissions.
- Practice `REVOKE` to remove a specific privilege.
- Run the full cleanup section to drop all lab objects.

## Best Practices

1. **Principle of Least Privilege** -- Grant only the minimum privileges a role needs
   to perform its job. Start narrow and widen only when a clear need arises.

2. **Always Roll Up to SYSADMIN** -- Every custom role should eventually be granted
   (directly or through a chain) to SYSADMIN. This ensures ACCOUNTADMIN can manage
   all objects without needing OWNERSHIP on each one.

3. **Avoid Using ACCOUNTADMIN Day-to-Day** -- Reserve ACCOUNTADMIN for initial setup
   and break-glass scenarios. Perform daily work under a lower-privileged role.

4. **Use Descriptive Role Names** -- Prefix roles with a project or team name
   (e.g., `FINANCE_ANALYST`, `MARKETING_READER`) so their purpose is obvious.

5. **Separate Duty Roles** -- Keep security administration (SECURITYADMIN) separate
   from object administration (SYSADMIN). Do not combine them into a single custom
   role.

6. **Audit Regularly** -- Periodically run `SHOW GRANTS` to review who has access to
   what. Remove stale grants promptly.

7. **Prefer Role Hierarchy Over Duplicate Grants** -- Instead of granting the same
   privilege to five roles, grant it once to the lowest role and let inheritance do
   the rest.

## Review Questions

1. **What is the difference between SYSADMIN and SECURITYADMIN?**
   SYSADMIN manages objects (databases, warehouses). SECURITYADMIN manages users,
   roles, and grants.

2. **Why should custom roles roll up to SYSADMIN?**
   So that ACCOUNTADMIN (which inherits SYSADMIN) retains the ability to manage all
   objects created under those custom roles.

3. **A user has WORKSHOP_DEVELOPER. Can they run SELECT on a table that only
   WORKSHOP_READER was granted SELECT on?**
   Yes. WORKSHOP_DEVELOPER inherits WORKSHOP_ANALYST, which inherits
   WORKSHOP_READER. Privileges cascade upward through the hierarchy.

4. **You REVOKE SELECT from WORKSHOP_ANALYST. Does WORKSHOP_READER lose SELECT?**
   No. Revoking from ANALYST only removes the direct grant on ANALYST. READER still
   holds its own direct grant.

5. **Name two privileges that apply to schemas but not to tables.**
   CREATE TABLE and CREATE VIEW (these are schema-level privileges that control
   whether a role can create new objects inside a schema).

6. **What command shows every privilege that has been granted to a specific role?**
   `SHOW GRANTS TO ROLE <role_name>;`

## Next Steps

Continue to **Lab 07** to explore **Data Sharing & Marketplace**, where you will
learn how to securely share data with other Snowflake accounts without copying it.
