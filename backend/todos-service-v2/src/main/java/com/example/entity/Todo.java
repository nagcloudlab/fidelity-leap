package com.example.entity;

import java.time.LocalDateTime;
import java.util.Objects;

public class Todo {

    private Long id;
    private String title;
    private boolean completed;
    private String description;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public Todo() {
    }

    public Todo(Long id, String title, boolean completed, String description, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.title = title;
        this.completed = completed;
        this.description = description;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public Long getId() {
        return id;
    }


    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void setCompleted(boolean completed) {
        this.completed = completed;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }


    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    @Override
    public String toString() {
        return "Todo{" +
                "id=" + id +
                ", title='" + title + '\'' +
                ", completed=" + completed +
                ", description='" + description + '\'' +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }


    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Todo todo)) return false;
        return completed == todo.completed && Objects.equals(id, todo.id) && Objects.equals(title, todo.title) && Objects.equals(description, todo.description) && Objects.equals(createdAt, todo.createdAt) && Objects.equals(updatedAt, todo.updatedAt);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, title, completed, description, createdAt, updatedAt);
    }
}
