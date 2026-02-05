package com.example.error;

import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@NoArgsConstructor
@AllArgsConstructor
public class HttpError {
    private String path;
    private  int statusCode;
    private  String message;
    private LocalDateTime timestamp;
}
