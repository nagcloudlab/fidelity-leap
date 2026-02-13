package com.example.gatewayservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClient;

@RestController
@RequestMapping("/api/v1")
public class OrderGatewayController {

    private final RestClient orderRestClient;

    public OrderGatewayController(RestClient orderRestClient) {
        this.orderRestClient = orderRestClient;
    }

    @GetMapping("/products")
    public ResponseEntity<String> getProducts() {
        String body = orderRestClient.get()
                .uri("/api/v1/products")
                .retrieve()
                .body(String.class);
        return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
    }

    @GetMapping("/orders")
    public ResponseEntity<String> getOrders() {
        String body = orderRestClient.get()
                .uri("/api/v1/orders")
                .retrieve()
                .body(String.class);
        return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
    }

    @GetMapping("/orders/{id}")
    public ResponseEntity<String> getOrderById(@PathVariable Long id) {
        String body = orderRestClient.get()
                .uri("/api/v1/orders/{id}", id)
                .retrieve()
                .body(String.class);
        return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
    }

    @PostMapping("/orders")
    public ResponseEntity<String> placeOrder(@RequestBody String request) {
        try {
            String body = orderRestClient.post()
                    .uri("/api/v1/orders")
                    .header("Content-Type", "application/json")
                    .body(request)
                    .retrieve()
                    .body(String.class);
            return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            return ResponseEntity.status(e.getStatusCode())
                    .header("Content-Type", "application/json")
                    .body(e.getResponseBodyAsString());
        }
    }
}
