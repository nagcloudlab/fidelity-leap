package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.ProviderManager;
import org.springframework.security.authorization.AuthorizationManager;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.intercept.RequestAuthorizationContext;

import java.util.List;

@Configuration
public class SecConfiguration {

    @Autowired
    private FidelityAuthenticationProvider fidelityAuthenticationProvider;
//
//    @Bean
//    public AuthenticationManager authenticationManager(HttpSecurity http) throws Exception {
//        return new ProviderManager(List.of(fidelityAuthenticationProvider));
//    }

//    @Bean
//    public FidelityAuthenticationFilter etsAuthenticationFilter(AuthenticationManager authenticationManager) {
//        FidelityAuthenticationFilter etsAuthenticationFilter = new FidelityAuthenticationFilter(authenticationManager);
//        etsAuthenticationFilter.setFilterProcessesUrl("/authenticate");
//        return etsAuthenticationFilter;
//    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .authorizeHttpRequests(authz -> authz
                        .requestMatchers("/", "/login", "/register", "/favicon.ico", "/authenticate").permitAll()
                        .requestMatchers(HttpMethod.POST, "/register").permitAll() // 🔐 allow form POST
                        .requestMatchers("/accounts/**").authenticated()
                )
                .exceptionHandling(ex -> ex
                        .accessDeniedPage("/access-denied")
                )
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.ALWAYS));


        return http.build();
    }

}
