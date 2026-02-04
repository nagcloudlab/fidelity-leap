package com.example.service;

import com.example.entity.Todo;
import com.example.entity.TodoType;
import com.example.repository.TodoRepository;
import org.slf4j.Logger;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service("todoService")
public class TodoServiceImpl implements TodoService {

    private static final Logger logger = org.slf4j.LoggerFactory.getLogger("todos-service");
    private final TodoRepository todoRepository;
    private ChatClient chatClient;

    @Autowired
    public TodoServiceImpl(TodoRepository todoRepository, ChatClient.Builder chatClientBuilder) {
        this.todoRepository = todoRepository;
        this.chatClient = chatClientBuilder.build();
        logger.info("TodoRepository injected into TodoServiceImpl");
        logger.info("TodoServiceImpl initialized");
    }

    @Override
    @Transactional
    public void createTodo(String title, String description) {
        logger.info("Creating Todo with title: {} and description: {}", title, description);


        // From description, determine the type of todo using AI
        String systemPrompt = """
                You are an expert task classifier.
                Classify the following task description into one of the following categories: WORK, PERSONAL, HEALTH, SHOPPING, OTHER.
                Respond with only the category name.
                Rules:
                - If the task is related to job, office, meetings, projects, classify as WORK
                - If the task is related to family, friends, social events, classify as PERSONAL
                - If the task is related to fitness, medical, wellness, classify as HEALTH
                - If the task is related to buying items, groceries, classify as SHOPPING
                - If none of the above, classify as OTHER
                """;
        String userPrompt = "Task Description: " + description;

        String todoType = chatClient.prompt()
                .system(systemPrompt)
                .user(userPrompt)
                .call()
                .content();

        Todo todo = new Todo();
        todo.setTitle(title);
        todo.setTodoType(TodoType.valueOf(todoType));
        todo.setDescription(description);
        todoRepository.save(todo);
    }

    @Override
    public void deleteTodo(long id) {
        logger.info("Deleting Todo with ID: {}", id);
        todoRepository.deleteById(id);
    }

    @Override
    public void updateTodo(long id, String title, String description) {
        logger.info("Updating Todo with ID: {} to title: {} and description: {}", id, title, description);
        Todo todo = todoRepository.findById(id).orElseThrow(() -> new RuntimeException("Todo not found"));
        if (todo != null) {
            todo.setTitle(title);
            todo.setDescription(description);
            todoRepository.save(todo);
        }
    }

    @Override
    public Todo getTodo(long id) {
        logger.info("Getting Todo with ID: {}", id);
        return todoRepository.findById(id).orElseThrow(() -> new RuntimeException("Todo not found"));
    }


}
