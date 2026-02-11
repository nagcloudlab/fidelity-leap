package com.example.dto;


import lombok.Data;

@Data
public class CreateUserRequestDto {
    private String username;
    private String password;
    private String email;
}
