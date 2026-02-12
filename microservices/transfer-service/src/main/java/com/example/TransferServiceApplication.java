package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;


class Account {
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
class TransferController {

    private RestTemplate restTemplate = new RestTemplate();

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @PostMapping("/transfer")
    public String transfer() {
        System.out.println("Initiating transfer...");
        String fromAccount = "123456";
        String toAccount = "654321";
        double amount = 100.0;
        // Load 'from' account details
        Account from = restTemplate.getForObject("http://localhost:8081/accounts/" + fromAccount, Account.class);
        // Load 'to' account details
        Account to = restTemplate.getForObject("http://localhost:8081/accounts/" + toAccount, Account.class);
        //
        if (from.getBalance() < amount) {
            return "Insufficient funds in account " + fromAccount;
        }
        // Withdraw from 'from' account
        restTemplate.put("http://localhost:8081/accounts/" + fromAccount + "/withdraw?amount=" + amount, null);
        // Deposit to 'to' account
        restTemplate.put("http://localhost:8081/accounts/" + toAccount + "/deposit?amount=" + amount, null);

        // Notification Message to kafka
        String notificationMessage = "Transferred " + amount + " from account " + fromAccount + " to account " + toAccount;
        kafkaTemplate.send("transfer-events", notificationMessage);

        System.out.println("Transfer completed successfully.");

        return "Transferred " + amount + " from account " + fromAccount + " to account " + toAccount;
    }

}


@SpringBootApplication
public class TransferServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(TransferServiceApplication.class, args);
    }

}
