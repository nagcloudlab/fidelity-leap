package com.example.analyticsservice.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;

@Configuration
public class SnowflakeDataSourceConfig {

    @Bean
    @ConfigurationProperties(prefix = "snowflake.datasource")
    public DataSource snowflakeDataSource() {
        return DataSourceBuilder.create()
                .type(com.zaxxer.hikari.HikariDataSource.class)
                .build();
    }

    @Bean
    public JdbcTemplate snowflakeJdbcTemplate(DataSource snowflakeDataSource) {
        return new JdbcTemplate(snowflakeDataSource);
    }
}
