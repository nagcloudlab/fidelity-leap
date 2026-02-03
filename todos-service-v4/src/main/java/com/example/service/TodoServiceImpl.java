package com.example.service;

import com.example.entity.Todo;
import com.example.repository.TodoRepository;
import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component("todoService")
public class TodoServiceImpl implements TodoService {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");
    private final TodoRepository todoRepository ;

    @Autowired
    public TodoServiceImpl(TodoRepository todoRepository){
        this.todoRepository= todoRepository;
        logger.info("TodoRepository injected into TodoServiceImpl");
        logger.info("TodoServiceImpl initialized");
    }

    @Override
    public void createTodo(String title, String description) {
        logger.info("Creating Todo with title: {} and description: {}", title, description);
        Todo todo = new Todo();
        todo.setTitle(title);
        todo.setDescription(description);
        todoRepository.save(todo);
    }

    @Override
    public void deleteTodo(long id) {
        logger.info("Deleting Todo with ID: {}", id);
        todoRepository.delete(id);
    }

    @Override
    public void updateTodo(long id, String title, String description) {
        logger.info("Updating Todo with ID: {} to title: {} and description: {}", id, title, description);
        Todo todo = todoRepository.findById(id);
        if (todo != null) {
            todo.setTitle(title);
            todo.setDescription(description);
            todoRepository.update(todo);
        }
    }

    @Override
    public Todo getTodo(long id) {
        logger.info("Getting Todo with ID: {}", id);
        return todoRepository.findById(id);
    }


}
