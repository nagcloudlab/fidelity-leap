package com.example.orderservice.client;

import com.example.orderservice.exception.ResourceNotFoundException;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;

import java.util.Map;

@Component
public class AccountsClient {

    private final RestClient restClient;

    public AccountsClient(RestClient accountsRestClient) {
        this.restClient = accountsRestClient;
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> checkBalance(String email, double amount) {
        try {
            return restClient.get()
                    .uri("/api/v1/accounts/{email}/check?amount={amount}", email, amount)
                    .retrieve()
                    .body(Map.class);
        } catch (HttpClientErrorException.NotFound e) {
            throw new ResourceNotFoundException("No account found for email: " + email + ". Please use a registered email.");
        }
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> debit(String email, double amount, Long orderId) {
        Map<String, Object> request = Map.of(
                "email", email,
                "amount", amount,
                "orderId", orderId
        );
        return restClient.post()
                .uri("/api/v1/accounts/{email}/debit", email)
                .body(request)
                .retrieve()
                .body(Map.class);
    }
}
