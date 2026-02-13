package com.example.gatewayservice.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;

@Configuration
public class RestClientConfig {

    @Value("${services.order.url}")
    private String orderServiceUrl;

    @Value("${services.accounts.url}")
    private String accountsServiceUrl;

    @Value("${services.analytics.url}")
    private String analyticsServiceUrl;

    @Bean
    public RestClient orderRestClient() {
        return RestClient.builder().baseUrl(orderServiceUrl).build();
    }

    @Bean
    public RestClient accountsRestClient() {
        return RestClient.builder().baseUrl(accountsServiceUrl).build();
    }

    @Bean
    public RestClient analyticsRestClient() {
        return RestClient.builder().baseUrl(analyticsServiceUrl).build();
    }
}
