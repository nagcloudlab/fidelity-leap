package com.example.web;


import com.example.dto.CreateTodoDto;
import com.example.entity.Todo;
import com.example.execption.UserNotFoundException;
import com.example.service.TodoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;

@Controller
public class TodoController {

    @Autowired
    private TodoService todoService;

    @GetMapping("/new-todo")
    public ModelAndView newTodoForm() {
        ModelAndView mav = new ModelAndView();
        mav.setViewName("todo-form");
        return mav;
    }

    @GetMapping("/todos")
    public ModelAndView listTodos() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        System.out.println("-".repeat(50));
        System.out.println("Authenticated User: " + authentication.getName());
        authentication.getAuthorities().forEach(grantedAuthority -> {
            System.out.println("Authority: " + grantedAuthority.getAuthority());
        });
        System.out.println("-".repeat(50));

        List<Todo> todos = todoService.listTodos(); // Model Data
        ModelAndView mav = new ModelAndView();
        mav.addObject("todos", todos); // Add Model Data to ModelAndView
        mav.setViewName("todos"); // View Name
        return mav;
    }

    @PostMapping("/todos")
    public String createTodo(@ModelAttribute CreateTodoDto createTodoDto) {
        todoService.createTodo(createTodoDto);
        return "redirect:/todos";
    }


    @ExceptionHandler(
            UserNotFoundException.class
    )
    public ModelAndView handleUserNotFoundException(UserNotFoundException ex) {
        ModelAndView mav = new ModelAndView();
        mav.addObject("errorMessage", ex.getMessage());
        mav.setViewName("error");
        return mav;
    }

}
