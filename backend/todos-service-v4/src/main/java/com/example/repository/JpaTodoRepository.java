package com.example.repository;

import com.example.entity.Todo;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.stereotype.Component;


@Component("jpaTodoRepository")
public class JpaTodoRepository implements TodoRepository {

    @PersistenceContext
    private EntityManager entityManager;

    @Override
    public void save(Todo todo) {
        entityManager.persist(todo);
    }

    @Override
    public Todo findById(Long id) {
        return null;
    }

    @Override
    public void delete(Long id) {

    }

    @Override
    public void update(Todo todo) {

    }
}
