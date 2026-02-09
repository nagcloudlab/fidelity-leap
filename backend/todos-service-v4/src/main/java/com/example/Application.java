package com.example;

import com.example.config.DataSourceConfiguration;
import com.example.service.TodoService;
import org.slf4j.Logger;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.transaction.annotation.EnableTransactionManagement;

@Configuration
@ComponentScan(basePackages = "com.example")
@Import({
        DataSourceConfiguration.class
})
@EnableTransactionManagement
public class Application {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");


    public static void main(String[] args) {

        //-----------------------------------------
        // Init / boot phase
        //-----------------------------------------
        logger.info("-".repeat(50));
        // based on configuration, initialize services, databases, etc.

        ConfigurableApplicationContext applicationContext = null;
        applicationContext = new AnnotationConfigApplicationContext(Application.class);


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Run phase
        //-----------------------------------------
        TodoService todoService = applicationContext.getBean("todoService", TodoService.class);
        todoService.createTodo("todo-3", "My third todo");


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Shutdown phase
        //-----------------------------------------
        logger.info("-".repeat(50));

    }
}
