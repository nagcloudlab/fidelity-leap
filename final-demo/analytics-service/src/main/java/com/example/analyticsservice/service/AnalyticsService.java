package com.example.analyticsservice.service;

import com.example.analyticsservice.dto.OrderSummaryDto;
import com.example.analyticsservice.dto.RecentOrderDto;
import com.example.analyticsservice.dto.TopProductDto;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class AnalyticsService {

    private final JdbcTemplate snowflakeJdbcTemplate;

    @Value("${snowflake.fallback.log-only:false}")
    private boolean logOnly;

    public AnalyticsService(JdbcTemplate snowflakeJdbcTemplate) {
        this.snowflakeJdbcTemplate = snowflakeJdbcTemplate;
    }

    // ---- WRITE: Insert order data into Star Schema ----

    public void writeOrderToSnowflake(JsonNode orderEvent) {
        long orderId = orderEvent.get("orderId").asLong();
        String customerName = orderEvent.get("customerName").asText();
        String customerEmail = orderEvent.get("customerEmail").asText();
        String orderDateStr = orderEvent.get("orderDate").asText();
        String status = orderEvent.get("status").asText();
        double totalAmount = orderEvent.get("totalAmount").asDouble();
        int itemCount = orderEvent.get("itemCount").asInt();

        LocalDateTime orderDate;
        try {
            orderDate = LocalDateTime.parse(orderDateStr, DateTimeFormatter.ISO_LOCAL_DATE_TIME);
        } catch (Exception e) {
            orderDate = LocalDateTime.now();
        }

        if (logOnly) {
            System.out.println("[FALLBACK] Would write order " + orderId + " to star schema");
            System.out.println("[FALLBACK]   Customer: " + customerName + " (" + customerEmail + ")");
            System.out.println("[FALLBACK]   Date: " + orderDate + ", Total: $" + totalAmount + ", Items: " + itemCount);
            JsonNode items = orderEvent.get("items");
            if (items != null) {
                for (JsonNode item : items) {
                    System.out.println("[FALLBACK]   Item: " + item.get("productName").asText() +
                            " (qty=" + item.get("quantity").asInt() + ", $" + item.get("lineTotal").asDouble() + ")");
                }
            }
            return;
        }

        // 1. Upsert DIM_CUSTOMER
        snowflakeJdbcTemplate.update(
                "MERGE INTO DIM_CUSTOMER t USING (SELECT ? AS EMAIL, ? AS NAME) s " +
                "ON t.CUSTOMER_EMAIL = s.EMAIL " +
                "WHEN MATCHED THEN UPDATE SET CUSTOMER_NAME = s.NAME " +
                "WHEN NOT MATCHED THEN INSERT (CUSTOMER_NAME, CUSTOMER_EMAIL) VALUES (s.NAME, s.EMAIL)",
                customerEmail, customerName);

        // 2. Upsert DIM_DATE
        String dateKey = orderDate.toLocalDate().toString(); // yyyy-MM-dd
        snowflakeJdbcTemplate.update(
                "MERGE INTO DIM_DATE t USING (SELECT ?::DATE AS DK) s " +
                "ON t.DATE_KEY = s.DK " +
                "WHEN NOT MATCHED THEN INSERT (DATE_KEY, DAY, MONTH, QUARTER, YEAR) " +
                "VALUES (s.DK, DAYOFMONTH(s.DK), MONTH(s.DK), QUARTER(s.DK), YEAR(s.DK))",
                dateKey);

        // Get customer surrogate key
        Long customerKey = snowflakeJdbcTemplate.queryForObject(
                "SELECT CUSTOMER_KEY FROM DIM_CUSTOMER WHERE CUSTOMER_EMAIL = ?",
                Long.class, customerEmail);

        // 3. Upsert DIM_PRODUCT + insert FACT_ORDER_ITEMS for each item
        JsonNode items = orderEvent.get("items");
        if (items != null) {
            for (JsonNode item : items) {
                long productId = item.get("productId").asLong();
                String productName = item.get("productName").asText();
                String category = item.has("category") ? item.get("category").asText() : "";
                String brand = item.has("brand") ? item.get("brand").asText() : "";

                snowflakeJdbcTemplate.update(
                        "MERGE INTO DIM_PRODUCT t USING (SELECT ? AS PID, ? AS PNAME, ? AS CAT, ? AS BRD) s " +
                        "ON t.PRODUCT_ID = s.PID " +
                        "WHEN MATCHED THEN UPDATE SET PRODUCT_NAME = s.PNAME, CATEGORY = s.CAT, BRAND = s.BRD " +
                        "WHEN NOT MATCHED THEN INSERT (PRODUCT_ID, PRODUCT_NAME, CATEGORY, BRAND) VALUES (s.PID, s.PNAME, s.CAT, s.BRD)",
                        productId, productName, category, brand);

                Long productKey = snowflakeJdbcTemplate.queryForObject(
                        "SELECT PRODUCT_KEY FROM DIM_PRODUCT WHERE PRODUCT_ID = ?",
                        Long.class, productId);

                snowflakeJdbcTemplate.update(
                        "INSERT INTO FACT_ORDER_ITEMS (ORDER_ID, CUSTOMER_KEY, PRODUCT_KEY, DATE_KEY, STATUS, QUANTITY, UNIT_PRICE, LINE_TOTAL) " +
                        "VALUES (?, ?, ?, ?::DATE, ?, ?, ?, ?)",
                        orderId, customerKey, productKey, dateKey, status,
                        item.get("quantity").asInt(),
                        item.get("unitPrice").asDouble(),
                        item.get("lineTotal").asDouble());
            }
        }

        System.out.println("Wrote order " + orderId + " to Star Schema (" + (items != null ? items.size() : 0) + " items)");
    }

    // ---- READ: Query Star Schema views ----

    public List<OrderSummaryDto> getDailySummary() {
        String sql = "SELECT ORDER_DAY, TOTAL_ORDERS, TOTAL_REVENUE, AVG_ORDER_VALUE, TOTAL_ITEMS " +
                "FROM V_DAILY_ORDER_SUMMARY ORDER BY ORDER_DAY DESC";
        return snowflakeJdbcTemplate.query(sql, (rs, rowNum) -> new OrderSummaryDto(
                rs.getString("ORDER_DAY"),
                rs.getInt("TOTAL_ORDERS"),
                rs.getDouble("TOTAL_REVENUE"),
                rs.getDouble("AVG_ORDER_VALUE"),
                rs.getInt("TOTAL_ITEMS")
        ));
    }

    public List<TopProductDto> getTopProducts() {
        String sql = "SELECT PRODUCT_NAME, TIMES_ORDERED, TOTAL_UNITS_SOLD, TOTAL_REVENUE, AVG_UNIT_PRICE " +
                "FROM V_PRODUCT_PERFORMANCE ORDER BY TOTAL_REVENUE DESC LIMIT 10";
        return snowflakeJdbcTemplate.query(sql, (rs, rowNum) -> new TopProductDto(
                rs.getString("PRODUCT_NAME"),
                rs.getInt("TIMES_ORDERED"),
                rs.getInt("TOTAL_UNITS_SOLD"),
                rs.getDouble("TOTAL_REVENUE"),
                rs.getDouble("AVG_UNIT_PRICE")
        ));
    }

    public List<RecentOrderDto> getRecentOrders() {
        String sql = "SELECT ORDER_ID, CUSTOMER_NAME, CUSTOMER_EMAIL, DATE_KEY AS ORDER_DATE, STATUS, TOTAL_AMOUNT, ITEM_COUNT " +
                "FROM V_RECENT_ORDERS LIMIT 20";
        return snowflakeJdbcTemplate.query(sql, (rs, rowNum) -> new RecentOrderDto(
                rs.getLong("ORDER_ID"),
                rs.getString("CUSTOMER_NAME"),
                rs.getString("CUSTOMER_EMAIL"),
                rs.getString("ORDER_DATE"),
                rs.getString("STATUS"),
                rs.getDouble("TOTAL_AMOUNT"),
                rs.getInt("ITEM_COUNT")
        ));
    }
}
