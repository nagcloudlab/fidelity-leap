package com.example;

import jakarta.annotation.PostConstruct;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.security.Principal;
import java.util.List;


@SpringBootApplication
public class SpringSecDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringSecDemoApplication.class, args);
    }


    @Bean
    public PasswordEncoder passwordEncoder() {
        return new org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder();
    }

    @Bean
    public CommandLineRunner runner(InMemoryUserStore userStore) {
        return args -> {
            System.out.println("Registered Users:");
            userStore.register("nag", "password", "domain1", List.of("ROLE_MANAGER"));
            userStore.register("malli", "password", "domain1", List.of("ROLE_EMPLOYEE"));
        };
    }

}
