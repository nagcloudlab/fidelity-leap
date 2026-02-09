package com.example;

import com.example.service.TodoServiceImpl;
import org.slf4j.Logger;

public class Application {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");


    public static void main(String[] args) {

        //-----------------------------------------
        // Init / boot phase
        //-----------------------------------------
        logger.info("-".repeat(50));
        // based on configuration, initialize services, databases, etc.
        TodoServiceImpl todoService = new TodoServiceImpl();


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Run phase
        //-----------------------------------------

        todoService.createTodo("Buy groceries", "Milk, Bread, Eggs");
        logger.info("-");
        todoService.updateTodo(1L, "Buy groceries and fruits", "Milk, Bread, Eggs, Apples");


        logger.info("-".repeat(50));
        //-----------------------------------------
        // Shutdown phase
        //-----------------------------------------
        logger.info("-".repeat(50));

    }
}
