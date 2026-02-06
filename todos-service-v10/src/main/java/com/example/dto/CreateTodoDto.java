package com.example.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Setter
@Getter
public class CreateTodoDto {
    @NotNull(message = "User ID must not be null")
    @NotBlank(message = "Title must not be blank")
    private String title;
    private String description;
    private long userId;
}
