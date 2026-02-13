package com.example.analyticsservice.controller;

import com.example.analyticsservice.dto.OrderSummaryDto;
import com.example.analyticsservice.dto.RecentOrderDto;
import com.example.analyticsservice.dto.TopProductDto;
import com.example.analyticsservice.service.AnalyticsService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/summary")
    public ResponseEntity<List<OrderSummaryDto>> getDailySummary() {
        return ResponseEntity.ok(analyticsService.getDailySummary());
    }

    @GetMapping("/top-products")
    public ResponseEntity<List<TopProductDto>> getTopProducts() {
        return ResponseEntity.ok(analyticsService.getTopProducts());
    }

    @GetMapping("/recent-orders")
    public ResponseEntity<List<RecentOrderDto>> getRecentOrders() {
        return ResponseEntity.ok(analyticsService.getRecentOrders());
    }
}
