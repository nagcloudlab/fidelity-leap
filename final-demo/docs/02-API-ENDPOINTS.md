# API Endpoints

All endpoints are accessible through the **API Gateway on port 8086**. The Angular UI uses the gateway as a single entry point.

## Order Service (port 8082)

| Method | Endpoint | Description | Request Body | Response |
|--------|---------|-------------|-------------|----------|
| GET | `/api/v1/products` | List all products (10 pre-loaded) | — | `Product[]` |
| GET | `/api/v1/orders` | List all orders (newest first) | — | `OrderResponse[]` |
| GET | `/api/v1/orders/{id}` | Get order by ID | — | `OrderResponse` |
| POST | `/api/v1/orders` | Place a new order (checks balance, debits, publishes Kafka) | `OrderRequest` | `OrderResponse` |

### OrderRequest

```json
{
  "customerName": "John Doe",
  "customerEmail": "john@example.com",
  "items": [
    { "productId": 1, "quantity": 2 }
  ]
}
```

### OrderResponse

```json
{
  "id": 253,
  "customerName": "John Doe",
  "customerEmail": "john@example.com",
  "orderDate": "2026-02-13T12:00:00",
  "status": "CONFIRMED",
  "totalAmount": 59.98,
  "items": [
    {
      "id": 253,
      "productId": 1,
      "productName": "Wireless Mouse",
      "quantity": 2,
      "unitPrice": 29.99,
      "lineTotal": 59.98
    }
  ]
}
```

## Accounts Service (port 8085)

| Method | Endpoint | Description | Request Body | Response |
|--------|---------|-------------|-------------|----------|
| GET | `/api/v1/accounts` | List all accounts | — | `Account[]` |
| GET | `/api/v1/accounts/{email}` | Get account by email | — | `Account` |
| GET | `/api/v1/accounts/{email}/check?amount=X` | Check if balance >= amount | — | `BalanceResponse` |
| POST | `/api/v1/accounts/{email}/debit` | Debit amount from account | `DebitRequest` | `DebitResponse` |

### BalanceResponse

```json
{
  "email": "john@example.com",
  "customerName": "John Doe",
  "balance": 440.02,
  "sufficient": true
}
```

### DebitRequest / DebitResponse

```json
// Request
{ "email": "john@example.com", "amount": 59.98, "orderId": 253 }

// Response
{ "email": "john@example.com", "newBalance": 380.04, "orderId": 253, "success": true }
```

### Pre-loaded Accounts

| Customer | Email | Balance |
|----------|-------|---------|
| John Doe | john@example.com | $500.00 |
| Jane Smith | jane@example.com | $1,000.00 |
| Bob Wilson | bob@example.com | $250.00 |
| Alice Brown | alice@example.com | $750.00 |
| Charlie Davis | charlie@example.com | $50.00 |

Charlie's low balance ($50) is intentional for demoing "insufficient balance" rejection.

## Analytics Service (port 8083)

| Method | Endpoint | Description | Source |
|--------|---------|-------------|--------|
| GET | `/api/v1/analytics/summary` | Daily order summary | V_DAILY_ORDER_SUMMARY |
| GET | `/api/v1/analytics/top-products` | Product performance metrics | V_PRODUCT_PERFORMANCE |
| GET | `/api/v1/analytics/recent-orders` | Recent orders | V_RECENT_ORDERS |

## Error Responses

All services return errors in a consistent format:

```json
{
  "timestamp": "2026-02-13T11:53:30.226024",
  "status": 400,
  "error": "Insufficient Balance",
  "message": "Insufficient balance for charlie@example.com. Available: $50.00, Required: $159.98",
  "path": "/api/v1/orders"
}
```

| Status | Error | When |
|--------|-------|------|
| 400 | Insufficient Balance | Balance too low for order |
| 404 | Not Found | Unknown email / order / product |
| 500 | Internal Server Error | Unexpected server error |
