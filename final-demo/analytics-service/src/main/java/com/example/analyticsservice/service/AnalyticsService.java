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

    // ---- WRITE: Insert order data into Snowflake ----

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

        String orderSql = "INSERT INTO ORDERS_ANALYTICS (ORDER_ID, CUSTOMER_NAME, CUSTOMER_EMAIL, ORDER_DATE, STATUS, TOTAL_AMOUNT, ITEM_COUNT) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";

        String itemSql = "INSERT INTO ORDER_ITEMS_ANALYTICS (ORDER_ID, PRODUCT_ID, PRODUCT_NAME, QUANTITY, UNIT_PRICE, LINE_TOTAL) " +
                "VALUES (?, ?, ?, ?, ?, ?)";

        if (logOnly) {
            System.out.println("[FALLBACK] Would execute: " + orderSql);
            System.out.println("[FALLBACK]   Values: " + orderId + ", " + customerName + ", " + customerEmail +
                    ", " + orderDate + ", " + status + ", " + totalAmount + ", " + itemCount);
            JsonNode items = orderEvent.get("items");
            if (items != null) {
                for (JsonNode item : items) {
                    System.out.println("[FALLBACK] Would execute: " + itemSql);
                    System.out.println("[FALLBACK]   Values: " + orderId + ", " + item.get("productId").asLong() +
                            ", " + item.get("productName").asText() + ", " + item.get("quantity").asInt() +
                            ", " + item.get("unitPrice").asDouble() + ", " + item.get("lineTotal").asDouble());
                }
            }
            return;
        }

        // Insert order header
        snowflakeJdbcTemplate.update(orderSql,
                orderId, customerName, customerEmail,
                Timestamp.valueOf(orderDate), status, totalAmount, itemCount);

        // Insert order items
        JsonNode items = orderEvent.get("items");
        if (items != null) {
            for (JsonNode item : items) {
                snowflakeJdbcTemplate.update(itemSql,
                        orderId,
                        item.get("productId").asLong(),
                        item.get("productName").asText(),
                        item.get("quantity").asInt(),
                        item.get("unitPrice").asDouble(),
                        item.get("lineTotal").asDouble());
            }
        }

        System.out.println("Wrote order " + orderId + " to Snowflake (" + (items != null ? items.size() : 0) + " items)");
    }

    // ---- READ: Query Snowflake views ----

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
        String sql = "SELECT ORDER_ID, CUSTOMER_NAME, CUSTOMER_EMAIL, ORDER_DATE, STATUS, TOTAL_AMOUNT, ITEM_COUNT " +
                "FROM ORDERS_ANALYTICS ORDER BY LOADED_AT DESC LIMIT 20";
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
