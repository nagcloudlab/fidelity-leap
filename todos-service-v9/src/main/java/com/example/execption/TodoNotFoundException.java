package com.example.execption;

public class TodoNotFoundException extends RuntimeException{
    public TodoNotFoundException(String message) {
        super(message);
    }
}
