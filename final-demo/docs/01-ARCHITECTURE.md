# Architecture Overview

## System Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         ANGULAR UI (port 4200)                          │
│          Products │ Place Order │ Order History │ Analytics              │
└─────────────────────────────────┬────────────────────────────────────────┘
                                  │ Single entry point
                                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                       API GATEWAY (port 8086)                           │
│                    Spring Boot — request routing                        │
│                                                                        │
│  /api/v1/products ─────► Order Service                                 │
│  /api/v1/orders ───────► Order Service                                 │
│  /api/v1/accounts/* ───► Accounts Service                              │
│  /api/v1/analytics/* ──► Analytics Service                             │
└────────┬─────────────────────┬─────────────────────┬───────────────────┘
         │                     │                     │
         ▼                     ▼                     ▼
┌─────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐
│  ORDER SERVICE  │  │ACCOUNTS SERVICE  │  │   ANALYTICS SERVICE      │
│   port 8082     │  │   port 8085      │  │     port 8083            │
│                 │  │                  │  │                          │
│  Spring Boot    │  │  Spring Boot     │  │  Spring Boot             │
│  H2 (OLTP)     │  │  H2 (Balances)   │  │                          │
│  Kafka Producer │  │                  │  │  WRITE: Kafka Consumer   │
│                 │  │  5 pre-loaded    │  │    → Snowflake INSERT    │
│  Products       │  │  accounts with   │  │                          │
│  Orders         │  │  balances        │  │  READ: JdbcTemplate      │
│  Order Items    │  │                  │  │    → Snowflake SELECT    │
└────────┬────────┘  └──────────────────┘  └────────┬─────────────────┘
         │                    ▲                     │
         │  SYNC REST         │                     │
         │  ① Check balance ──┘                     │
         │  ② Debit balance ──┘                     │
         │                                          │
         │  ASYNC Kafka                             ▼
         ▼                                ┌─────────────────────┐
┌──────────────────┐                      │     SNOWFLAKE       │
│      KAFKA       │                      │   (OLAP - Cloud)    │
│  "order-events"  │                      │                     │
│    topic         │                      │  ★ STAR SCHEMA ★    │
└──────┬───────────┘                      │                     │
       │                                  │  DIM_CUSTOMER       │
  ┌────┴─────┐                            │  DIM_PRODUCT        │
  ▼          ▼                            │  DIM_DATE           │
┌────────┐ ┌──────────┐                   │  FACT_ORDER_ITEMS   │
│NOTIF.  │ │ANALYTICS │                   │                     │
│SERVICE │ │SERVICE   │── MERGE/INSERT ──►│  Views:             │
│ 8084   │ │ 8083     │◄── SELECT ───────│  V_DAILY_SUMMARY    │
│        │ │          │                   │  V_PRODUCT_PERF     │
│Console │ │Kafka     │                   │  V_RECENT_ORDERS    │
│ logs   │ │Consumer  │                   │                     │
└────────┘ └──────────┘                   └─────────────────────┘
```

## Service Inventory

| Service | Port | Technology | Responsibility |
|---------|------|-----------|----------------|
| Angular UI | 4200 | Angular 21, Bootstrap 5 | SPA frontend — products, orders, analytics |
| API Gateway | 8086 | Spring Boot 4.0.2 | Single entry point, routes requests to backends |
| Order Service | 8082 | Spring Boot, H2, Kafka | OLTP — products, orders, Kafka event publishing |
| Accounts Service | 8085 | Spring Boot, H2 | Balance check and debit for customers |
| Analytics Service | 8083 | Spring Boot, Snowflake JDBC, Kafka | Kafka consumer → Snowflake writer + REST read API |
| Notification Service | 8084 | Spring Boot, Kafka | Kafka consumer — logs order notifications |
| Kafka | 9092 | Apache Kafka | Async message broker — "order-events" topic |
| Snowflake | Cloud | Snowflake (OLAP) | Star schema analytics storage |

## Communication Patterns

### Synchronous REST — "Need answer NOW"

Used between Order Service and Accounts Service. The balance check **must** succeed before the order is confirmed.

```
Order Service ──► Accounts Service
  "Does John have $60?"  ──► "Yes" ──► save order ──► "Debit $60" ──► "Done"
```

**When to use sync:** When the caller needs the result to proceed (e.g., can't confirm an order without knowing the balance).

### Asynchronous Kafka — "Fire and forget"

Used after order confirmation. Order Service publishes an event; downstream services consume independently.

```
Order Service ──► Kafka ──► Notification Service (logs to console)
                       ──► Analytics Service (writes to Snowflake)
```

**When to use async:** When the caller doesn't need the result (e.g., notifications and analytics can happen later, independently).

## Data Flow — One Order Journey

```
 1. User picks "John Doe" ──► UI shows balance: $440
 2. User selects "Wireless Mouse x2" ──► UI shows total: $59.98
 3. Click "Place Order"
 4. UI ──► Gateway ──► Order Service
 5. Order Service ──► Accounts Service: checkBalance ✓
 6. Order Service ──► H2: save order
 7. Order Service ──► Accounts Service: debit $59.98
 8. Order Service ──► Kafka: publish event (with category + brand)
 9. Notification Service ◄── Kafka: prints confirmation
10. Analytics Service ◄── Kafka:
      MERGE → DIM_CUSTOMER (John Doe)
      MERGE → DIM_PRODUCT (Wireless Mouse, Electronics, TechBrand)
      MERGE → DIM_DATE (2026-02-13)
      INSERT → FACT_ORDER_ITEMS (qty=2, $59.98)
11. Dashboard ──► Snowflake views ──► updated charts
```
