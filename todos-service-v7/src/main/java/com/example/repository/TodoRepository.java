package com.example.repository;

import com.example.entity.Todo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Repository;

import java.util.List;

//@Component
@Repository
public interface TodoRepository extends JpaRepository<Todo, Long> {

    // Method DSL
    List<Todo> findByCompleted(boolean completed);

}
