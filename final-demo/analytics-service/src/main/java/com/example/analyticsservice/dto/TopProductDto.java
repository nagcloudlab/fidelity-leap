package com.example.analyticsservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class TopProductDto {
    private String productName;
    private int timesOrdered;
    private int totalUnitsSold;
    private double totalRevenue;
    private double avgUnitPrice;
}
