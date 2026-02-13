# Service Details

## 1. Order Service (port 8082)

**Purpose:** OLTP service — manages products, orders, and order items. Publishes Kafka events after order confirmation.

**Package:** `com.example.orderservice`

### Key Classes

| Class | Package | Responsibility |
|-------|---------|---------------|
| `OrderServiceApplication` | root | Spring Boot entry point |
| `OrderController` | controller | REST endpoints for orders |
| `ProductController` | controller | REST endpoints for products |
| `OrderService` | service | Order creation with balance check, Kafka publishing |
| `Order` | entity | JPA entity — order header |
| `OrderItem` | entity | JPA entity — order line items (@OneToMany) |
| `Product` | entity | JPA entity — product catalog |
| `OrderEventPublisher` | event | Kafka producer — publishes to "order-events" topic |
| `OrderEvent` | event | Event payload with order + item details |
| `AccountsClient` | client | RestClient calls to accounts-service |
| `RestClientConfig` | config | RestClient bean for accounts-service |
| `CorsConfig` | config | CORS for localhost:4200 |
| `GlobalExceptionHandler` | exception | Handles ResourceNotFound, InsufficientBalance, validation |

### Order Creation Flow (`OrderService.createOrder()`)

```
1. Build Order + OrderItems from request
2. Calculate totalAmount
3. Call accountsClient.checkBalance(email, totalAmount)
4. If insufficient → throw InsufficientBalanceException (400)
5. Save order to H2
6. Call accountsClient.debit(email, totalAmount, orderId)
7. Publish OrderEvent to Kafka (includes category + brand)
8. Return OrderResponseDto
```

### Database (H2)

- URL: `jdbc:h2:file:./data/orderdb`
- Console: http://localhost:8082/h2-console
- Tables: PRODUCT (10 pre-loaded), ORDERS, ORDER_ITEMS

---

## 2. Accounts Service (port 8085)

**Purpose:** Manages customer accounts and balances. Provides balance check and debit operations called synchronously by order-service.

**Package:** `com.example.accountsservice`

### Key Classes

| Class | Package | Responsibility |
|-------|---------|---------------|
| `AccountsServiceApplication` | root | Spring Boot entry point |
| `AccountController` | controller | REST endpoints for accounts |
| `AccountService` | service | Balance check, debit with @Transactional |
| `Account` | entity | JPA entity — id, customerName, customerEmail, balance |
| `AccountRepository` | repository | JpaRepository + findByCustomerEmail() |
| `BalanceResponse` | dto | email, customerName, balance, sufficient |
| `DebitRequest` | dto | email, amount, orderId |
| `DebitResponse` | dto | email, newBalance, orderId, success |
| `AccountNotFoundException` | exception | Thrown when email not found (404) |
| `InsufficientBalanceException` | exception | Thrown when balance too low (400) |

### Database (H2)

- URL: `jdbc:h2:file:./data/accountsdb`
- Console: http://localhost:8085/h2-console
- Table: ACCOUNTS (5 pre-loaded customers)

---

## 3. Analytics Service (port 8083)

**Purpose:** Dual role — (1) consumes Kafka events and writes to Snowflake star schema, (2) serves analytics REST API reading from Snowflake views.

**Package:** `com.example.analyticsservice`

### Key Classes

| Class | Package | Responsibility |
|-------|---------|---------------|
| `AnalyticsServiceApplication` | root | Spring Boot entry point |
| `AnalyticsController` | controller | REST endpoints for analytics views |
| `AnalyticsService` | service | Write: Kafka → Snowflake. Read: Snowflake → REST |
| `OrderEventConsumer` | consumer | @KafkaListener on "order-events" topic |
| `SnowflakeDataSourceConfig` | config | HikariCP + JdbcTemplate for Snowflake |

### Write Path (Kafka → Snowflake)

```
Kafka event received by @KafkaListener
  → Parse JSON with ObjectMapper
  → MERGE into DIM_CUSTOMER
  → MERGE into DIM_DATE
  → For each item:
      → MERGE into DIM_PRODUCT
      → INSERT into FACT_ORDER_ITEMS
```

### Read Path (Snowflake → REST)

```
GET /summary     → SELECT from V_DAILY_ORDER_SUMMARY
GET /top-products → SELECT from V_PRODUCT_PERFORMANCE
GET /recent-orders → SELECT from V_RECENT_ORDERS
```

### Configuration

- Snowflake JDBC with `JDBC_QUERY_RESULT_FORMAT=JSON` (avoids Arrow library issues)
- Fallback mode: `snowflake.fallback.log-only=true` logs SQL instead of executing

---

## 4. Notification Service (port 8084)

**Purpose:** Kafka consumer that logs order notifications to console. Demonstrates the pub/sub pattern where multiple consumers process the same event independently.

**Key Class:** `NotificationServiceApplication` with `@KafkaListener`

### Console Output

```
========================================
   ORDER NOTIFICATION RECEIVED
========================================
   Order ID    : 253
   Customer    : John Doe
   Email       : john@example.com
   Total       : $59.98
   Items       : 2
   Status      : CONFIRMED
========================================
```

---

## 5. API Gateway (port 8086)

**Purpose:** Single entry point for the Angular UI. Routes requests to the correct backend service. Handles error propagation (4xx/5xx).

**Package:** `com.example.gatewayservice`

### Routing

| UI Request | Routed To |
|-----------|-----------|
| `/api/v1/products` | Order Service (8082) |
| `/api/v1/orders` | Order Service (8082) |
| `/api/v1/accounts/*` | Accounts Service (8085) |
| `/api/v1/analytics/*` | Analytics Service (8083) |

### Key Classes

| Class | Responsibility |
|-------|---------------|
| `OrderGatewayController` | Proxies product + order requests |
| `AccountsGatewayController` | Proxies account/balance requests |
| `AnalyticsGatewayController` | Proxies analytics requests with error handling |
| `RestClientConfig` | RestClient beans for each backend service |

---

## 6. Angular UI (port 4200)

**Purpose:** Single-page application with 4 main views.

### Routes

| Path | Component | Description |
|------|-----------|-------------|
| `/products` | ProductList | Browse product catalog, click "Order" |
| `/order` | OrderForm | Customer dropdown, product selection, balance check |
| `/orders` | OrderHistory | Table of past orders |
| `/analytics` | AnalyticsDashboard | Daily summary, top products, recent orders |

### Services

| File | Calls |
|------|-------|
| `order.service.ts` | Gateway → products, orders |
| `accounts.service.ts` | Gateway → accounts, balance check |
| `analytics.service.ts` | Gateway → Snowflake analytics views |

### Key Features

- Angular 21 standalone components with signals
- Customer account dropdown with live balance display
- Insufficient balance warning before submission
- Error handling for 400/404 responses
- Bootstrap 5 responsive styling
