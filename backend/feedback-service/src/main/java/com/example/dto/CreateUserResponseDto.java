package com.example.dto;


import lombok.Data;

@Data
public class CreateUserResponseDto {
    private String username;
    private String email;
    private  String message;
}
