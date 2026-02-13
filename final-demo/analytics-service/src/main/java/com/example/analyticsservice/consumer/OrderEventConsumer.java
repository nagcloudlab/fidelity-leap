package com.example.analyticsservice.consumer;

import com.example.analyticsservice.service.AnalyticsService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
public class OrderEventConsumer {

    private final AnalyticsService analyticsService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public OrderEventConsumer(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @KafkaListener(topics = "order-events", groupId = "order-analytics-group")
    public void handleOrderEvent(String event) {
        try {
            JsonNode orderEvent = objectMapper.readTree(event);
            System.out.println("Analytics: Received order event for orderId=" + orderEvent.get("orderId").asText());
            analyticsService.writeOrderToSnowflake(orderEvent);
        } catch (Exception e) {
            System.err.println("Analytics: Failed to process order event: " + e.getMessage());
        }
    }
}
