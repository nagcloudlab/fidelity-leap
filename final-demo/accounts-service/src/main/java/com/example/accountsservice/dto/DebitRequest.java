package com.example.accountsservice.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

@Data
public class DebitRequest {
    @NotNull
    private String email;

    @NotNull
    @Positive
    private Double amount;

    private Long orderId;
}
