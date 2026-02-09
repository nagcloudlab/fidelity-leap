package com.example.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

@Configuration
public class DataSourceConfiguration {

    @Bean("dataSource")
    public DataSource dataSource() {
        // Configure and return the necessary JDBC DataSource
        // This is a placeholder implementation
        org.apache.commons.dbcp2.BasicDataSource dataSource = new org.apache.commons.dbcp2.BasicDataSource();
        dataSource.setDriverClassName("com.mysql.cj.jdbc.Driver");
        dataSource.setUrl("jdbc:mysql://localhost:3306/todos_db");
        dataSource.setUsername("root");
        dataSource.setPassword("root");
        return dataSource;
    }

}
