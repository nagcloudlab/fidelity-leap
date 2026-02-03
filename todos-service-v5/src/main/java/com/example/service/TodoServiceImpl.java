package com.example.service;

import com.example.entity.Todo;
import com.example.repository.TodoRepository;
import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

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
    @Transactional
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
        todoRepository.deleteById(id);
    }

    @Override
    public void updateTodo(long id, String title, String description) {
        logger.info("Updating Todo with ID: {} to title: {} and description: {}", id, title, description);
        Todo todo = todoRepository.findById(id).orElseThrow(()-> new RuntimeException("Todo not found"));
        if (todo != null) {
            todo.setTitle(title);
            todo.setDescription(description);
            todoRepository.save(todo);
        }
    }

    @Override
    public Todo getTodo(long id) {
        logger.info("Getting Todo with ID: {}", id);
        return todoRepository.findById(id).orElseThrow(()-> new RuntimeException("Todo not found"));
    }


}
