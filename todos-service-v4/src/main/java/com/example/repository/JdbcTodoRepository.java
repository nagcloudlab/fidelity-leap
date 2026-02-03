package com.example.repository;

import com.example.entity.Todo;
import org.slf4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;

@Component("jdbcTodoRepository")
public class JdbcTodoRepository implements TodoRepository {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");
    private final JdbcTemplate jdbcTemplate;

    @Autowired
    public JdbcTodoRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
        logger.info("JdbcTodoRepository initialized");
    }


    @Override
    public void save(Todo todo) {
        logger.info("Saving Todo: {}", todo);
        // Implementation for saving a Todo item to the database
        String sql = "INSERT INTO todos (title,description) VALUES (?,?)";
        jdbcTemplate.update(sql, todo.getTitle(), todo.getDescription());
    }

    @Override
    public Todo findById(Long id) {
        logger.info("Finding Todo by ID: {}", id);
        // Implementation for finding a Todo item by its ID
        return null;
    }

    @Override
    public void delete(Long id) {
        logger.info("Deleting Todo by ID: {}", id);
        // Implementation for deleting a Todo item by its ID
    }

    @Override
    public void update(Todo todo) {
        logger.info("Updating Todo: {}", todo);
        // Implementation for updating a Todo item in the database
    }

}
