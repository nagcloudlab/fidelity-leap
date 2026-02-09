package com.example.day3.dto;

public record TransferRequestRecord(
    String fromAccountId,
    String toAccountId,
    double amount
) {
}
