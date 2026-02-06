package com.example.service;

import com.example.dto.CreateTodoDto;
import com.example.entity.Todo;
import com.example.entity.TodoType;
import com.example.entity.User;
import com.example.execption.UserNotFoundException;
import com.example.repository.TodoRepository;
import com.example.repository.UserRepository;
import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service("todoService")
public class TodoServiceImpl implements TodoService {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");
    @Autowired
    private  TodoRepository todoRepository;
    @Autowired
    private UserRepository userRepository;

    public TodoServiceImpl() {
        logger.info("TodoRepository injected into TodoServiceImpl");
        logger.info("TodoServiceImpl initialized");
    }

    @Override
    @Transactional(
            transactionManager = "transactionManager",
            rollbackFor = {RuntimeException.class},
            noRollbackFor = {UserNotFoundException.class},
            timeout = 10,
            isolation = Isolation.READ_COMMITTED,
            propagation = Propagation.REQUIRES_NEW
    )
    public Todo createTodo(CreateTodoDto createTodoDto) {
        logger.info("Creating Todo with title: {}", createTodoDto.getTitle());
        Todo todo = new Todo();
        todo.setTitle(createTodoDto.getTitle());
        todo.setDescription(createTodoDto.getDescription());
        todo.setTodoType(TodoType.OTHER);
        // db-call - read
        User user=userRepository.findById(createTodoDto.getUserId())
                        .orElseThrow(()->new UserNotFoundException("User not found with id: " + createTodoDto.getUserId()));
        todo.setUser(user);
        // db-call - write
        todo=todoRepository.save(todo);
        user.setTodosCount(user.getTodosCount()+1);
        boolean isFailed=false;
        if(isFailed){
            throw new RuntimeException("Simulated failure after creating todo");
        }
        // db-call - write
        userRepository.save(user);
        logger.info("Created Todo: {}", todo);
        return todo;
    }

    @Override
    public void deleteTodo(long id) {
        logger.info("Deleting Todo with ID: {}", id);
        todoRepository.deleteById(id);
    }

    @Override
    public void updateTodo(long id, String title, String description) {
        logger.info("Updating Todo with ID: {} to title: {} and description: {}", id, title, description);
        Todo todo = todoRepository.findById(id).orElseThrow(() -> new RuntimeException("Todo not found"));
        if (todo != null) {
            todo.setTitle(title);
            todo.setDescription(description);
            todoRepository.save(todo);
        }
    }

    @Override
    public Todo getTodo(long id) {
        logger.info("Getting Todo with ID: {}", id);
        return todoRepository.findById(id).orElseThrow(() -> new RuntimeException("Todo not found"));
    }

    @Override
    public List<Todo> listTodos() {
        return todoRepository.findAll();
    }


}
