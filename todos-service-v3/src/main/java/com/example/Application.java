package com.example;

import com.example.repository.JdbcTodoRepository;
import com.example.repository.TodoRepository;
import com.example.service.TodoService;
import com.example.service.TodoServiceImpl;
import org.slf4j.Logger;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class Application {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");


    public static void main(String[] args) {

        //-----------------------------------------
        // Init / boot phase
        //-----------------------------------------
        logger.info("-".repeat(50));
        // based on configuration, initialize services, databases, etc.

        ConfigurableApplicationContext applicationContext = null;
        applicationContext = new ClassPathXmlApplicationContext("todos-service.xml");


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Run phase
        //-----------------------------------------
        TodoService todoService = applicationContext.getBean("todoService", TodoService.class);
        todoService.createTodo("Buy groceries", "Milk, Bread, Eggs");


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Shutdown phase
        //-----------------------------------------
        logger.info("-".repeat(50));

    }
}
