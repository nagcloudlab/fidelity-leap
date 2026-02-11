package com.example.controller;


import com.example.entity.Feedback;
import com.example.entity.User;
import com.example.repository.FeedbackRepository;
import com.example.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/feedbacks")
public class FeedbackApiController {

    private FeedbackRepository feedbackRepository;
    private UserRepository userRepository;

    public FeedbackApiController(FeedbackRepository feedbackRepository, UserRepository userRepository) {
        this.feedbackRepository = feedbackRepository;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<?> getAllFeedbacks() {
        Authentication authentication = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        if(username.equals("admin")) {
            return ResponseEntity.ok(feedbackRepository.findAll());
        } else {
            User user = userRepository.findByUsername(username).orElseThrow(() -> new RuntimeException("User not found"));
            return ResponseEntity.ok(feedbackRepository.findByUserId(user.getId()));
        }
    }

    @PostMapping
    public ResponseEntity<?> createFeedback(@RequestBody Feedback feedback) {
        Authentication authentication = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        userRepository.findByUsername(username).ifPresent(user -> feedback.setUser(user));
        Feedback savedFeedback = feedbackRepository.save(feedback);
        // status code 201: Created
        return ResponseEntity.status(201).body(savedFeedback);
    }


    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteFeedback(@RequestParam Long id) {
        Authentication authentication = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        if(!username.equals("admin")) {
            return ResponseEntity.status(403).body("Forbidden: Only admin can delete feedback");
        }
        feedbackRepository.deleteById(id);
        // status code 204: No Content
        return ResponseEntity.noContent().build();
    }


}
