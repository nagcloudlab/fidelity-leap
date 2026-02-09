package com.example.web;


import com.example.dto.CreateTodoDto;
import com.example.entity.Todo;
import com.example.execption.UserNotFoundException;
import com.example.service.TodoService;
import org.springframework.beans.factory.annotation.Autowired;
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
        // Authorization logic can be added here if needed
        ModelAndView mav = new ModelAndView();
        mav.setViewName("todo-form");
        return mav;
    }

    @GetMapping("/todos")
    public ModelAndView listTodos() {
        List<Todo> todos = todoService.listTodos(); // Model Data
        ModelAndView mav = new ModelAndView();
        mav.addObject("todos", todos); // Add Model Data to ModelAndView
        mav.setViewName("todos"); // View Name
        return mav;
    }

    @PostMapping("/todos")
    public String createTodo(@ModelAttribute CreateTodoDto createTodoDto) {
        createTodoDto.setUserId(2L);
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
