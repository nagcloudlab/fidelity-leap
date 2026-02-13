package com.example.notificationservice;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.KafkaListener;

@SpringBootApplication
public class NotificationServiceApplication {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @KafkaListener(topics = "order-events", groupId = "order-notification-group")
    public void handleOrderEvent(String event) {
        try {
            JsonNode json = objectMapper.readTree(event);
            System.out.println("========================================");
            System.out.println("   ORDER NOTIFICATION RECEIVED");
            System.out.println("========================================");
            System.out.println("   Order ID    : " + json.get("orderId").asText());
            System.out.println("   Customer    : " + json.get("customerName").asText());
            System.out.println("   Email       : " + json.get("customerEmail").asText());
            System.out.println("   Total       : $" + json.get("totalAmount").asText());
            System.out.println("   Items       : " + json.get("itemCount").asText());
            System.out.println("   Status      : " + json.get("status").asText());
            System.out.println("========================================");
            System.out.println("   Email notification sent to " + json.get("customerEmail").asText());
            System.out.println("========================================");
        } catch (Exception e) {
            System.out.println("Received order event: " + event);
        }
    }

    public static void main(String[] args) {
        SpringApplication.run(NotificationServiceApplication.class, args);
    }
}
