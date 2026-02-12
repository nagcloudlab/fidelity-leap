package com.example.demo;

import jakarta.annotation.PostConstruct;
import jakarta.persistence.*;
import lombok.Data;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.time.LocalDateTime;
import java.util.UUID;

@Configuration
class DataSourceConfig {

    @Bean
    @Primary
    @ConfigurationProperties(prefix = "spring.datasource")
    public DataSource mysqlDataSource() {
        return DataSourceBuilder.create()
                .type(com.zaxxer.hikari.HikariDataSource.class)
                .build();
    }

    @Bean
    @ConfigurationProperties(prefix = "snowflake.datasource")
    public DataSource snowflakeDataSource() {
        return DataSourceBuilder.create()
                .type(com.zaxxer.hikari.HikariDataSource.class)
                .build();
    }

    @Bean
    public JdbcTemplate snowflakeJdbcTemplate(
            @Qualifier("snowflakeDataSource") DataSource dataSource) {
        return new JdbcTemplate(dataSource);
    }
}


@Data
@Entity
@Table(name = "accounts")
class Account {
    @Id
    private String number;
    private double balance;
}

enum TransactionType {
    DEPOSIT, WITHDRAWAL
}

@Data
class Transaction {
    private String id;
    private double amount;
    private TransactionType type;
    private LocalDateTime timestamp;
    private Account account;
}

interface AccountRepository extends JpaRepository<Account, String> {
    // Repository methods for Account
}


@Service
class TransferService {
    private final AccountRepository accountRepository;
    private final JdbcTemplate snowflakeJdbcTemplate;

    public TransferService(AccountRepository accountRepository,  JdbcTemplate snowflakeJdbcTemplate) {
        this.accountRepository = accountRepository;
        this.snowflakeJdbcTemplate = snowflakeJdbcTemplate;
    }

    @Transactional
    public void transfer(String fromAccountNumber, String toAccountNumber, double amount) {
        Account fromAccount = accountRepository.findById(fromAccountNumber).orElseThrow();
        Account toAccount = accountRepository.findById(toAccountNumber).orElseThrow();

        if (fromAccount.getBalance() < amount) {
            throw new IllegalArgumentException("Insufficient funds");
        }

        fromAccount.setBalance(fromAccount.getBalance() - amount);
        toAccount.setBalance(toAccount.getBalance() + amount);

        accountRepository.save(fromAccount);
        accountRepository.save(toAccount);

        Transaction withdrawal = new Transaction();
        withdrawal.setId(UUID.randomUUID().toString());
        withdrawal.setAmount(amount);
        withdrawal.setType(TransactionType.WITHDRAWAL);
        withdrawal.setTimestamp(LocalDateTime.now());
        withdrawal.setAccount(fromAccount);

        Transaction deposit = new Transaction();
        deposit.setId(UUID.randomUUID().toString());
        deposit.setAmount(amount);
        deposit.setType(TransactionType.DEPOSIT);
        deposit.setTimestamp(LocalDateTime.now());
        deposit.setAccount(toAccount);

        // using snowflakeJdbcTemplate to insert transactions into Snowflake
        String insertSql = "INSERT INTO transactions (id,amount, type, timestamp, account_number) VALUES (?,?, ?, ?, ?)";
        // Convert LocalDateTime to Timestamp for Snowflake compatibility
        snowflakeJdbcTemplate.update(insertSql, withdrawal.getId(), withdrawal.getAmount(), withdrawal.getType().name(),
                java.sql.Timestamp.valueOf(withdrawal.getTimestamp()), withdrawal.getAccount().getNumber());
        snowflakeJdbcTemplate.update(insertSql, deposit.getId(), deposit.getAmount(), deposit.getType().name(),
                java.sql.Timestamp.valueOf(deposit.getTimestamp()), deposit.getAccount().getNumber());
        System.out.println("Transferred " + amount + " from account " + fromAccountNumber + " to account " + toAccountNumber);
    }
}




@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }



    @Bean
    public CommandLineRunner demo(TransferService transferService) {
        return (args) -> {
            // Example usage of the transfer service
            transferService.transfer("123456", "654321", 100.0);
        };
    }


}
