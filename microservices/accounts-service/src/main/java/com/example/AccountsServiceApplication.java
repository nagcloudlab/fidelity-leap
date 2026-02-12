package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RestController;

class Account{
	private String accountNumber;
	private String accountHolderName;
	private double balance;

	public Account(String accountNumber, String accountHolderName, double balance) {
		this.accountNumber = accountNumber;
		this.accountHolderName = accountHolderName;
		this.balance = balance;
	}

	public String getAccountNumber() {
		return accountNumber;
	}

	public String getAccountHolderName() {
		return accountHolderName;
	}

	public double getBalance() {
		return balance;
	}
}

@RestController
class AccountController {
	@GetMapping("/accounts/{accountNumber}")
	public Account getAccountDetails(@PathVariable String accountNumber) {
		System.out.println("Fetching details for account: " + accountNumber);
		// In a real application, you would fetch account details from a database
		return new Account(accountNumber, "John Doe", 1000.00);
	}
	@PutMapping("/accounts/{accountNumber}/deposit")
	public String deposit(@PathVariable String accountNumber, double amount) {
		System.out.println("Depositing " + amount + " to account: " + accountNumber);
		// In a real application, you would update the account balance in a database
		return "Deposited " + amount + " to account " + accountNumber;
	}
	@PutMapping("/accounts/{accountNumber}/withdraw")
	public String withdraw(@PathVariable String accountNumber, double amount) {
		System.out.println("Withdrawing " + amount + " from account: " + accountNumber);
		// In a real application, you would update the account balance in a database
		return "Withdrew " + amount + " from account " + accountNumber;
	}
}


@SpringBootApplication
public class AccountsServiceApplication {

	public static void main(String[] args) {
		SpringApplication.run(AccountsServiceApplication.class, args);
	}

}
