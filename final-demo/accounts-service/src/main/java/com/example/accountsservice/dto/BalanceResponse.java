package com.example.accountsservice.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class BalanceResponse {
    private String email;
    private String customerName;
    private Double balance;
    private boolean sufficient;
}
