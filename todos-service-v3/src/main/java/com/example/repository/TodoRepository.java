package com.example.repository;

import com.example.entity.Todo;

public interface TodoRepository {
    void save(Todo todo);
    Todo findById(Long id);
    void delete(Long id);
    void update(Todo todo);
}
