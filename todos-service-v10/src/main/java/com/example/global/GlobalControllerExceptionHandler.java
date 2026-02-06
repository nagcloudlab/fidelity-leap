package com.example.global;

import com.example.execption.HttpErrorInfo;
import com.example.execption.TodoNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestControllerAdvice
public class GlobalControllerExceptionHandler {

    @ExceptionHandler(TodoNotFoundException.class)
    public @ResponseBody ResponseEntity<HttpErrorInfo> handleNotFoundExceptions(
            HttpServletRequest request,
            TodoNotFoundException ex) {
        HttpErrorInfo error = new HttpErrorInfo(
                request.getRequestURI(),
                HttpStatus.NOT_FOUND.value(),
                ex.getMessage(),
                LocalDateTime.now()
        );
        return ResponseEntity
                .status(HttpStatus.NOT_FOUND)
                .header("Content-Type","application/json")
                .body(error);
    }
}
