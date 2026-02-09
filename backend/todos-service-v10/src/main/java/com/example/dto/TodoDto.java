package com.example.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class TodoDto {

    private Integer id;
    private String title;
    private String description;
    private boolean completed;
    private Integer userId;


}
