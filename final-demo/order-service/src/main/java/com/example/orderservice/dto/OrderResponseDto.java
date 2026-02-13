package com.example.orderservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@AllArgsConstructor
public class OrderResponseDto {
    private Long id;
    private String customerName;
    private String customerEmail;
    private LocalDateTime orderDate;
    private String status;
    private double totalAmount;
    private List<OrderItemResponseDto> items;

    @Data
    @AllArgsConstructor
    public static class OrderItemResponseDto {
        private Long id;
        private Long productId;
        private String productName;
        private int quantity;
        private double unitPrice;
        private double lineTotal;
    }
}
