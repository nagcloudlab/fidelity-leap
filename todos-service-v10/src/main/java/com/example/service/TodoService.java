package com.example.service;

import com.example.dto.CreateTodoDto;
import com.example.entity.Todo;

import java.util.List;

public interface TodoService {
    Todo createTodo(CreateTodoDto createTodoDto);

    void deleteTodo(long id);

    void updateTodo(long id, String title, String description);

    Todo getTodo(long id);

    List<Todo> listTodos();
}
