# Demo Script: Order Analytics Platform

Total Duration: ~65 minutes

---

## Act 1: OLTP Side (15 min)

**Technologies:** Java, Spring Boot, JPA, H2

### What to Show

1. **Walk through Order Service code:**
   - `Product.java` entity with fixed IDs
   - `Order.java` + `OrderItem.java` with `@OneToMany` relationship
   - `OrderService.java` with `@Transactional` order creation
   - `data.sql` pre-loaded products

2. **Start order-service:**
   ```bash
   cd order-service
   mvn spring-boot:run
   ```

3. **Show product catalog:**
   ```bash
   curl http://localhost:8082/api/v1/products | python3 -m json.tool
   ```

4. **Show H2 Console:**
   - Open http://localhost:8082/h2-console
   - JDBC URL: `jdbc:h2:file:./data/orderdb`
   - Show PRODUCT table with 10 rows

### Key Talking Points
- JPA entity relationships (`@OneToMany`, `@ManyToOne`)
- `@CreationTimestamp` for automatic date tracking
- H2 as embedded OLTP database
- `data.sql` with `MERGE` for idempotent seeding

---

## Act 2: Place an Order (10 min)

**Technologies:** Angular, REST, @Transactional

### What to Show

1. **Start Angular UI:**
   ```bash
   cd order-ui
   ng serve
   ```

2. **Browse Products:** Navigate to http://localhost:4200/products

3. **Click "Order" on a product** - navigates to order form with product pre-selected

4. **Fill in order form:**
   - Customer Name: `John Doe`
   - Email: `john@example.com`
   - Product: Wireless Mouse
   - Quantity: 3

5. **Submit order** - show success message

6. **View Order History:** Navigate to /orders - show the order in the table

7. **Show H2 Console:** Query ORDERS and ORDER_ITEMS tables

### Key Talking Points
- Angular standalone components with signals
- `HttpClient` service pattern
- `@Valid` request body validation
- `@Transactional` ensures order + items saved atomically

---

## Act 3: Event-Driven Architecture (10 min)

**Technologies:** Kafka, @KafkaListener, Pub/Sub

### What to Show

1. **Walk through Kafka producer code:**
   - `OrderEventPublisher.java` - KafkaTemplate + JSON serialization
   - `OrderService.java` - event published after order saved

2. **Start Notification Service:**
   ```bash
   cd notification-service
   mvn spring-boot:run
   ```

3. **Show the `@KafkaListener`** in NotificationServiceApplication.java

4. **Place another order** via Angular UI

5. **Show notification console output:**
   ```
   ========================================
      ORDER NOTIFICATION RECEIVED
   ========================================
      Order ID    : 2
      Customer    : Jane Smith
      Email       : jane@example.com
      Total       : $159.98
      Items       : 2
      Status      : CONFIRMED
   ========================================
   ```

### Key Talking Points
- Kafka topics as event bus
- Producer/Consumer pattern with `@KafkaListener`
- JSON serialization of events
- Multiple consumers on the same topic (notification + analytics)

---

## Act 4: OLAP Side (15 min)

**Technologies:** Snowflake, JDBC, JdbcTemplate

### What to Show

1. **Walk through Analytics Service code:**
   - `SnowflakeDataSourceConfig.java` - HikariDataSource + JdbcTemplate
   - `OrderEventConsumer.java` - `@KafkaListener` receives order events
   - `AnalyticsService.java` - INSERT into Snowflake tables

2. **Start Analytics Service:**
   ```bash
   cd analytics-service
   mvn spring-boot:run
   ```

3. **Place an order** via Angular UI

4. **Show analytics console:**
   ```
   Analytics: Received order event for orderId=3
   Wrote order 3 to Snowflake (2 items)
   ```

5. **Query Snowflake in Snowsight:**
   ```sql
   SELECT * FROM WORKSHOP_DB.ANALYTICS.ORDERS_ANALYTICS;
   SELECT * FROM WORKSHOP_DB.ANALYTICS.ORDER_ITEMS_ANALYTICS;
   SELECT * FROM WORKSHOP_DB.ANALYTICS.V_DAILY_ORDER_SUMMARY;
   SELECT * FROM WORKSHOP_DB.ANALYTICS.V_PRODUCT_PERFORMANCE;
   ```

6. **Show Analytics Dashboard** in Angular at /analytics

### Key Talking Points
- OLTP (H2) vs OLAP (Snowflake) separation
- JdbcTemplate for direct SQL against Snowflake
- Analytical views for pre-aggregated data
- Fallback mode for demos without Snowflake

---

## Act 5: Streams & Tasks (10 min)

**Technologies:** Snowflake Streams, Tasks

### What to Show

1. **Run stream/task setup script** in Snowsight:
   ```sql
   -- snowflake/03_stream_and_task.sql
   ```

2. **Place more orders** to generate data

3. **Check stream:**
   ```sql
   SELECT SYSTEM$STREAM_HAS_DATA('ORDERS_ANALYTICS_STREAM');
   SELECT * FROM ORDERS_ANALYTICS_STREAM;
   ```

4. **Wait for task execution** (1 minute)

5. **Show REALTIME_ORDER_SUMMARY:**
   ```sql
   SELECT * FROM REALTIME_ORDER_SUMMARY;
   ```

6. **Check task history:**
   ```sql
   SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
       TASK_NAME => 'REFRESH_ORDER_SUMMARY',
       SCHEDULED_TIME_RANGE_START => DATEADD('HOUR', -1, CURRENT_TIMESTAMP())
   ));
   ```

### Key Talking Points
- CDC (Change Data Capture) with Snowflake Streams
- Scheduled tasks with `WHEN` conditions
- MERGE for upsert operations
- Real-time data pipeline without external tools

---

## Act 6: Architecture Review (5 min)

### What to Show

Draw or display the full architecture diagram:

```
Angular UI (4200)
    │
    ├── GET /products ──────► Order Service (8082, H2)
    ├── POST /orders ───────► Order Service ──► Kafka "order-events"
    ├── GET /orders ────────►                      │
    │                                    ┌─────────┼──────────┐
    │                                    ▼                    ▼
    │                         Notification (8084)    Analytics (8083)
    │                         Console logs           Snowflake JDBC
    │                                                     │
    └── GET /analytics/* ──────────────────────────► Snowflake Views
```

### Key Talking Points
- Microservices: each service has a single responsibility
- Event-driven: Kafka decouples services
- OLTP vs OLAP: right tool for the right job
- Full stack: Angular + Spring Boot + Snowflake
- Production patterns: CORS, validation, error handling, DTOs

---

## Troubleshooting

| Issue | Solution |
|-------|---------|
| Kafka connection refused | Start Kafka on localhost:9092 |
| Snowflake timeout | Check credentials in analytics-service application.properties |
| No analytics data | Set `snowflake.fallback.log-only=false` and verify Snowflake tables exist |
| CORS errors | Ensure services have CorsConfig allowing localhost:4200 |
| H2 console blank | Use JDBC URL `jdbc:h2:file:./data/orderdb` with user `sa` |
