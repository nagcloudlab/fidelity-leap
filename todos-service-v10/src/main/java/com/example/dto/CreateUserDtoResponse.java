package com.example.dto;

import lombok.Data;

@Data
public class CreateUserResponse {
    private Long id;
    private String username;
    private String email;
}
