package com.example.gatewayservice.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClient;

@RestController
@RequestMapping("/api/v1/accounts")
public class AccountsGatewayController {

    private final RestClient accountsRestClient;

    public AccountsGatewayController(RestClient accountsRestClient) {
        this.accountsRestClient = accountsRestClient;
    }

    @GetMapping
    public ResponseEntity<String> getAllAccounts() {
        String body = accountsRestClient.get()
                .uri("/api/v1/accounts")
                .retrieve()
                .body(String.class);
        return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
    }

    @GetMapping("/{email}")
    public ResponseEntity<String> getAccount(@PathVariable String email) {
        String body = accountsRestClient.get()
                .uri("/api/v1/accounts/{email}", email)
                .retrieve()
                .body(String.class);
        return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
    }

    @GetMapping("/{email}/check")
    public ResponseEntity<String> checkBalance(@PathVariable String email,
                                                @RequestParam double amount) {
        String body = accountsRestClient.get()
                .uri("/api/v1/accounts/{email}/check?amount={amount}", email, amount)
                .retrieve()
                .body(String.class);
        return ResponseEntity.ok().header("Content-Type", "application/json").body(body);
    }

    @PostMapping("/{email}/debit")
    public ResponseEntity<String> debit(@PathVariable String email,
                                         @RequestBody String request) {
        try {
            String body = accountsRestClient.post()
                    .uri("/api/v1/accounts/{email}/debit", email)
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
