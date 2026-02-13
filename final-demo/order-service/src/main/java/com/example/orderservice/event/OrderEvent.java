package com.example.orderservice.event;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class OrderEvent {
    private Long orderId;
    private String customerName;
    private String customerEmail;
    private LocalDateTime orderDate;
    private String status;
    private double totalAmount;
    private int itemCount;
    private List<OrderItemEvent> items;

    @Data
    @AllArgsConstructor
    @NoArgsConstructor
    public static class OrderItemEvent {
        private Long productId;
        private String productName;
        private String category;
        private String brand;
        private int quantity;
        private double unitPrice;
        private double lineTotal;
    }
}
