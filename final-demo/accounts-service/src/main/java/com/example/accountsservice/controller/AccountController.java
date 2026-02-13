package com.example.accountsservice.controller;

import com.example.accountsservice.dto.BalanceResponse;
import com.example.accountsservice.dto.DebitRequest;
import com.example.accountsservice.dto.DebitResponse;
import com.example.accountsservice.entity.Account;
import com.example.accountsservice.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping
    public List<Account> getAllAccounts() {
        return accountService.getAllAccounts();
    }

    @GetMapping("/{email}")
    public Account getAccountByEmail(@PathVariable String email) {
        return accountService.getAccountByEmail(email);
    }

    @GetMapping("/{email}/check")
    public BalanceResponse checkBalance(@PathVariable String email,
                                        @RequestParam double amount) {
        return accountService.checkBalance(email, amount);
    }

    @PostMapping("/{email}/debit")
    public ResponseEntity<DebitResponse> debit(@PathVariable String email,
                                                @Valid @RequestBody DebitRequest request) {
        DebitResponse response = accountService.debit(email, request);
        return ResponseEntity.ok(response);
    }
}
