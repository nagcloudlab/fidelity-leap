package com.example.api;

import com.example.dto.CreateTodoDto;
import com.example.dto.TodoDto;
import com.example.entity.Todo;
import com.example.execption.TodoNotFoundException;
import com.example.repository.TodoRepository;
import com.example.service.TodoService;

import jakarta.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/todos")
public class TodoApiController {

        @Autowired
        private TodoService todoService;
        @Autowired
        private TodoRepository todoRepository;

        // read operations

        @GetMapping(params = { "!limit" })
        public List<TodoDto> getTodos() {
                return todoRepository.findAll()
                                .stream()
                                .map(todo -> new TodoDto(
                                                todo.getId(),
                                                todo.getTitle(),
                                                todo.getDescription(),
                                                todo.isCompleted(),
                                                todo.getUser().getId()))
                                .toList();
        }

        @GetMapping(params = { "limit" })
        public List<TodoDto> getTodos(@RequestParam int limit) {
                return todoRepository.findAll()
                                .stream()
                                .limit(limit)
                                .map(todo -> new TodoDto(
                                                todo.getId(),
                                                todo.getTitle(),
                                                todo.getDescription(),
                                                todo.isCompleted(),
                                                todo.getUser().getId()))
                                .toList();
        }

        @GetMapping(params = { "limit" }, headers = { "language" })
        public ResponseEntity<?> getTodosByHeader(@RequestParam int limit, @RequestHeader String language) {
                System.out.println("Language Header: " + language);
                List<TodoDto> todos = todoRepository.findAll()
                                .stream()
                                .limit(limit)
                                .map(todo -> new TodoDto(
                                                todo.getId(),
                                                todo.getTitle(),
                                                todo.getDescription(),
                                                todo.isCompleted(),
                                                todo.getUser().getId()))
                                .toList();
                // send custom header in response
                return ResponseEntity.ok()
                                .header("language", language.toUpperCase())
                                .body(todos);
        }

        @GetMapping(value = "/{todoId}", produces = { "application/json" })
        public ResponseEntity<?> getTodoById(@PathVariable Long todoId) {
                Todo todo = todoRepository.findById(todoId)
                                .orElseThrow(() -> new TodoNotFoundException("Todo not found with id: " + todoId));
                TodoDto todoDto = new TodoDto(
                                todo.getId(),
                                todo.getTitle(),
                                todo.getDescription(),
                                todo.isCompleted(),
                                todo.getUser().getId());
                return ResponseEntity.ok(todoDto);

        }

        @RequestMapping(method = RequestMethod.HEAD, value = "/{todoId}")
        public ResponseEntity<?> headTodoById(@PathVariable Long todoId) {
                Optional<Todo> todo = todoRepository.findById(todoId);
                if (todo.isPresent()) {
                        return ResponseEntity.ok().build();
                } else {
                        return ResponseEntity.notFound().build();
                }
        }

        // OPTIONS
        @RequestMapping(method = RequestMethod.OPTIONS, value = "/{todoId}")
        public ResponseEntity<?> optionsTodos() {
                return ResponseEntity.ok()
                                .allow(HttpMethod.GET)
                                .build();
        }

        // write operations
        @PostMapping
        public ResponseEntity<?> createTodo(@RequestBody @Valid CreateTodoDto createTodoDto) {

                // ...
                // way-1 : Programmatically
                // way-2 : Declaratively using Validation Annotations

                Todo todo = new Todo();
                todo.setTitle(createTodoDto.getTitle());
                todo.setDescription(createTodoDto.getDescription());
                todo.setCompleted(false); // default value
                // Here we should set the user as well, assuming user with id exists
                // For simplicity, we are skipping user assignment
                // Todo savedTodo = todoRepository.save(todo);
                createTodoDto.setUserId(2L);
                Todo savedTodo = todoService.createTodo(createTodoDto);
                TodoDto todoDto = new TodoDto(
                                savedTodo.getId(),
                                savedTodo.getTitle(),
                                savedTodo.getDescription(),
                                savedTodo.isCompleted(),
                                savedTodo.getUser() != null ? savedTodo.getUser().getId() : null);
                return ResponseEntity.status(201).body(todoDto);
        }

        @PutMapping("/{todoId}")
        public ResponseEntity<?> updateTodo(@PathVariable Long todoId, @RequestBody CreateTodoDto updateTodoDto) {
                Todo existingTodo = todoRepository.findById(todoId)
                                .orElseThrow(() -> new TodoNotFoundException("Todo not found with id: " + todoId));
                existingTodo.setTitle(updateTodoDto.getTitle());
                existingTodo.setDescription(updateTodoDto.getDescription());
                todoRepository.save(existingTodo);
                return ResponseEntity.ok().build();
        }

        @DeleteMapping("/{todoId}")
        public ResponseEntity<?> deleteTodo(@PathVariable Long todoId) {
                Todo existingTodo = todoRepository.findById(todoId)
                                .orElseThrow(() -> new TodoNotFoundException("Todo not found with id: " + todoId));
                todoRepository.delete(existingTodo);
                return ResponseEntity.noContent().build();
        }

}
