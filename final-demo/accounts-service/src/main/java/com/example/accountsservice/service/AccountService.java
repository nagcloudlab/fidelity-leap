package com.example.accountsservice.service;

import com.example.accountsservice.dto.BalanceResponse;
import com.example.accountsservice.dto.DebitRequest;
import com.example.accountsservice.dto.DebitResponse;
import com.example.accountsservice.entity.Account;
import com.example.accountsservice.exception.AccountNotFoundException;
import com.example.accountsservice.exception.InsufficientBalanceException;
import com.example.accountsservice.repository.AccountRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AccountService {

    private final AccountRepository accountRepository;

    public AccountService(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    public List<Account> getAllAccounts() {
        return accountRepository.findAll();
    }

    public Account getAccountByEmail(String email) {
        return accountRepository.findByCustomerEmail(email)
                .orElseThrow(() -> new AccountNotFoundException("Account not found for email: " + email));
    }

    public BalanceResponse checkBalance(String email, double amount) {
        Account account = getAccountByEmail(email);
        return new BalanceResponse(
                account.getCustomerEmail(),
                account.getCustomerName(),
                account.getBalance(),
                account.getBalance() >= amount
        );
    }

    @Transactional
    public DebitResponse debit(String email, DebitRequest request) {
        Account account = getAccountByEmail(email);

        if (account.getBalance() < request.getAmount()) {
            throw new InsufficientBalanceException(
                    "Insufficient balance for " + email +
                    ". Available: $" + String.format("%.2f", account.getBalance()) +
                    ", Required: $" + String.format("%.2f", request.getAmount()));
        }

        account.setBalance(account.getBalance() - request.getAmount());
        accountRepository.save(account);

        return new DebitResponse(
                account.getCustomerEmail(),
                account.getBalance(),
                request.getOrderId(),
                true
        );
    }
}
