package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootApplication
public class DemoWithSnowflakeApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext applicationContext=
        SpringApplication.run(DemoWithSnowflakeApplication.class, args);
    }

    @Bean
    public CommandLineRunner run(JdbcTemplate jdbcTemplate) {
        return args -> {
            String sql = "SELECT * FROM demo_db.public.customers;";
            jdbcTemplate.queryForList(sql).forEach(row -> System.out.println(row));
        };
    }

}
