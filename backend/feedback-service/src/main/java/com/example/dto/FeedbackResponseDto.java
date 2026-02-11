package com.example.dto;

import java.time.LocalDateTime;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class FeedbackResponseDto {
    private Long id;
    private String mood;
    private int rating;
    private String comment;
    private LocalDateTime createdAt;
    private String username;
}
