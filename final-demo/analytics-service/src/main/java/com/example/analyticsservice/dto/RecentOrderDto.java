package com.example.analyticsservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class RecentOrderDto {
    private long orderId;
    private String customerName;
    private String customerEmail;
    private String orderDate;
    private String status;
    private double totalAmount;
    private int itemCount;
}
