package com.example;

import com.example.service.TodoService;
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

@Configuration
@ComponentScan(basePackages = "com.example")
@EnableTransactionManagement
@EnableAutoConfiguration
@EnableJpaRepositories
public class Application {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");


    public static void main(String[] args) {

        //-----------------------------------------
        // Init / boot phase
        //-----------------------------------------
        logger.info("-".repeat(50));
        // based on configuration, initialize services, databases, etc.

        ConfigurableApplicationContext applicationContext = null;
        applicationContext = SpringApplication.run(Application.class, args);


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Run phase
        //-----------------------------------------
        TodoService todoService = applicationContext.getBean("todoService", TodoService.class);
        todoService.createTodo("Buy New Laptop", "neeed to Macbook pro 16 inch");


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Shutdown phase
        //-----------------------------------------
        logger.info("-".repeat(50));

    }
}
