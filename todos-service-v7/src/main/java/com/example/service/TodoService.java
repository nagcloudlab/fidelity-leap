package com.example.service;

import com.example.dto.CreateTodoDto;
import com.example.entity.Todo;

public interface TodoService {
    void createTodo(CreateTodoDto createTodoDto);

    void deleteTodo(long id);

    void updateTodo(long id, String title, String description);

    Todo getTodo(long id);
}
