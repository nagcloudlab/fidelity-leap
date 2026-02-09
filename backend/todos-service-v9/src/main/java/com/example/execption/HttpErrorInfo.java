package com.example.execption;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@NoArgsConstructor
@AllArgsConstructor
@Data
public class HttpErrorInfo {
    private String path;
    private  int statusCode;
    private  String message;
    private LocalDateTime timestamp;
}
