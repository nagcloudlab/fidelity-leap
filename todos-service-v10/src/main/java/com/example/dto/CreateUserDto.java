package com.example.dto;


import lombok.*;

@AllArgsConstructor
@NoArgsConstructor
@Setter
@Getter
@Data
public class CreateUserDto {
    private String username;
    private String email;
    private String password;
}
