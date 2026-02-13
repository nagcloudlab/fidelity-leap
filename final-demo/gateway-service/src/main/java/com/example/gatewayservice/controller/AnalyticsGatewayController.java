package com.example.gatewayservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestClient;

@RestController
@RequestMapping("/api/v1/analytics")
public class AnalyticsGatewayController {

    private final RestClient analyticsRestClient;

    public AnalyticsGatewayController(RestClient analyticsRestClient) {
        this.analyticsRestClient = analyticsRestClient;
    }

    @GetMapping("/summary")
    public ResponseEntity<String> getSummary() {
        return proxy("/api/v1/analytics/summary");
    }

    @GetMapping("/top-products")
    public ResponseEntity<String> getTopProducts() {
        return proxy("/api/v1/analytics/top-products");
    }

    @GetMapping("/recent-orders")
    public ResponseEntity<String> getRecentOrders() {
        return proxy("/api/v1/analytics/recent-orders");
    }

    private ResponseEntity<String> proxy(String uri) {
        try {
            String body = analyticsRestClient.get()
                    .uri(uri)
                    .retrieve()
                    .body(String.class);
            return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
        } catch (HttpClientErrorException | HttpServerErrorException e) {
            return ResponseEntity.status(e.getStatusCode())
                    .header("Content-Type", "application/json")
                    .body(e.getResponseBodyAsString());
        } catch (Exception e) {
            return ResponseEntity.status(503)
                    .header("Content-Type", "application/json")
                    .body("{\"message\":\"Analytics service unavailable: " + e.getMessage().replace("\"", "'") + "\"}");
        }
    }
}
