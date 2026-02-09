package com.example.service;

import com.example.entity.Todo;

public interface TodoService {
    void createTodo(String title, String description);

    void deleteTodo(long id);

    void updateTodo(long id, String title, String description);

    Todo getTodo(long id);
}
