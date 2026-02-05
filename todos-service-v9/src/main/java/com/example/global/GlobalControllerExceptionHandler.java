package com.example.global;

import com.example.execption.HttpErrorInfo;
import com.example.execption.TodoNotFoundException;
import com.example.execption.UserNotFoundException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;

@RestControllerAdvice
public class GlobalAdviceController {

    @ExceptionHandler(
            value = {TodoNotFoundException.class}
    )
    public @ResponseBody ResponseEntity<HttpErrorInfo> handleNotFoundExceptions(
            HttpServletRequest request,
            TodoNotFoundException ex) {

        System.out.println("-----------------------------");
        System.out.println("Handling TodoNotFoundException");
        System.out.println("-----------------------------");

        HttpErrorInfo error = new HttpErrorInfo(
                request.getRequestURI(),
                HttpStatus.NOT_FOUND.value(),
                ex.getMessage(),
                LocalDateTime.now()
        );

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
}
