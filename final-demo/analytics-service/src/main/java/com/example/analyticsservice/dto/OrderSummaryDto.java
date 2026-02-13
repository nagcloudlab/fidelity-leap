package com.example.analyticsservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class OrderSummaryDto {
    private String orderDay;
    private int totalOrders;
    private double totalRevenue;
    private double avgOrderValue;
    private int totalItems;
}
