package com.example;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class Account{
    private String accountNumber;
    private String accountHolderName;
    private String accountType;
    private double balance;
}
