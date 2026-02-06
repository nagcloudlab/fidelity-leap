package com.example.dto;

import lombok.Data;

@Data
public class CreateUserDtoResponse {
    private Integer id;
    private String username;
    private String email;
}
