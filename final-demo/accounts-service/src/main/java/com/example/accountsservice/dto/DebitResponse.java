package com.example.accountsservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DebitResponse {
    private String email;
    private Double newBalance;
    private Long orderId;
    private boolean success;
}
