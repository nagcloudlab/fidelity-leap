package com.example.service;

import com.example.entity.Todo;
import com.example.repository.JdbcTodoRepository;
import org.slf4j.Logger;

public class TodoServiceImpl {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");

    public TodoServiceImpl(){
        logger.info("TodoServiceImpl initialized");
    }

    public void createTodo(String title, String description) {
        logger.info("Creating Todo with title: {} and description: {}", title, description);
        JdbcTodoRepository todoRepository = new JdbcTodoRepository();
        Todo todo = new Todo();
        todo.setTitle(title);
        todo.setDescription(description);
        todoRepository.save(todo);
    }

    public void deleteTodo(long id) {
        logger.info("Deleting Todo with ID: {}", id);
        JdbcTodoRepository todoRepository = new JdbcTodoRepository();
        todoRepository.delete(id);
    }

    public void updateTodo(long id, String title, String description) {
        logger.info("Updating Todo with ID: {} to title: {} and description: {}", id, title, description);
        JdbcTodoRepository todoRepository = new JdbcTodoRepository();
        Todo todo = todoRepository.findById(id);
        if (todo != null) {
            todo.setTitle(title);
            todo.setDescription(description);
            todoRepository.update(todo);
        }
    }

    public Todo getTodo(long id) {
        logger.info("Getting Todo with ID: {}", id);
        JdbcTodoRepository todoRepository = new JdbcTodoRepository();
        return todoRepository.findById(id);
    }


}
