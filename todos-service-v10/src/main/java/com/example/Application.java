package com.example;

import com.example.dto.CreateTodoDto;
import com.example.dto.CreateUserDto;
import com.example.service.TodoService;
import com.example.service.UserService;
import org.slf4j.Logger;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.transaction.annotation.EnableTransactionManagement;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

@Configuration
@ComponentScan(basePackages = "com.example")
@EnableTransactionManagement
@EnableAutoConfiguration
@EnableJpaRepositories
@EnableWebMvc
public class Application {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");

    public static void main(String[] args) {

        // -----------------------------------------
        // Init / boot phase
        // -----------------------------------------
        logger.info("-".repeat(50));
        // based on configuration, initialize services, databases, etc.
        ConfigurableApplicationContext applicationContext = null;
        applicationContext = SpringApplication.run(Application.class, args);

    }
}
