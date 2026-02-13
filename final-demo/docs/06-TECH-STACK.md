# Technology Stack

## Overview

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Frontend | Angular | 21 | SPA with standalone components and signals |
| Frontend | Bootstrap | 5 | Responsive UI styling |
| Gateway | Spring Boot | 4.0.2 | API gateway — single UI entry point |
| Backend | Spring Boot | 4.0.2 | Microservices framework |
| Backend | Spring Data JPA | — | ORM for H2 databases |
| Backend | Spring Web MVC | — | REST controllers |
| Backend | Spring Validation | — | @Valid request body validation |
| Backend | RestClient | — | Synchronous service-to-service HTTP calls |
| Backend | Lombok | — | Boilerplate reduction (@Data, @AllArgsConstructor) |
| OLTP Database | H2 | 2.4 | Embedded file-based database for orders and accounts |
| Messaging | Apache Kafka | 3.x | Async event-driven pub/sub |
| OLAP Database | Snowflake | Cloud | Analytics storage with star schema |
| OLAP Driver | Snowflake JDBC | — | JdbcTemplate queries against Snowflake |
| Build | Maven | 3.9+ | Dependency management and build |
| Language | Java | 17 | All backend services |
| Language | TypeScript | — | Angular frontend |

## OLTP vs OLAP

| | OLTP (H2) | OLAP (Snowflake) |
|---|---|---|
| **Purpose** | Transactional operations | Analytical queries |
| **Optimized for** | Fast reads/writes of single rows | Scanning/aggregating large datasets |
| **Schema** | Normalized (3NF) | Star schema (denormalized) |
| **Used by** | Order Service, Accounts Service | Analytics Service |
| **Data size** | Small (current orders) | Large (historical analytics) |
| **Query pattern** | `SELECT * FROM orders WHERE id = ?` | `SELECT SUM(total) GROUP BY date` |

## Microservices Patterns Demonstrated

| Pattern | Where | Description |
|---------|-------|-------------|
| API Gateway | gateway-service | Single entry point for all frontend requests |
| Synchronous REST | order → accounts | Request/response for balance check |
| Async Messaging | order → Kafka → notification/analytics | Fire-and-forget event publishing |
| Database per Service | Each service has its own H2 | No shared database between services |
| Event-Driven Architecture | Kafka topic "order-events" | Loose coupling between producer and consumers |
| CQRS-lite | analytics-service | Write path (Kafka) is separate from read path (REST) |
| Star Schema | Snowflake | DIM/FACT tables for analytics |

## Directory Structure

```
final-demo/
├── gateway-service/            # Spring Boot, API Gateway
├── order-service/              # Spring Boot, H2, Kafka Producer
├── accounts-service/           # Spring Boot, H2, Balance Check + Debit
├── analytics-service/          # Spring Boot, Kafka Consumer, Snowflake JDBC
├── notification-service/       # Spring Boot, Kafka Consumer
├── order-ui/                   # Angular 21 standalone app
├── snowflake/                  # Snowflake SQL scripts
│   ├── 01_setup_analytics_tables.sql
│   ├── 02_create_views.sql
│   ├── 03_stream_and_task.sql
│   └── 04_verify_queries.sql
├── docs/                       # Project documentation
├── README.md
└── DEMO-SCRIPT.md
```
