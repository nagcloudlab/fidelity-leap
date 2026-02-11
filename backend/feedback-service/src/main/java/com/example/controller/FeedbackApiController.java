package com.example.controller;

import com.example.dto.FeedbackRequestDto;
import com.example.dto.FeedbackResponseDto;
import com.example.security.UserPrincipal;
import com.example.service.FeedbackService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/feedbacks")
public class FeedbackApiController {

    private final FeedbackService feedbackService;

    public FeedbackApiController(FeedbackService feedbackService) {
        this.feedbackService = feedbackService;
    }

    @GetMapping
    public ResponseEntity<List<FeedbackResponseDto>> getAllFeedbacks(Authentication authentication) {
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        return ResponseEntity.ok(feedbackService.getAllFeedbacks(principal));
    }

    @PostMapping
    public ResponseEntity<FeedbackResponseDto> createFeedback(@Valid @RequestBody FeedbackRequestDto dto,
                                                               Authentication authentication) {
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        FeedbackResponseDto response = feedbackService.createFeedback(dto, principal);
        return ResponseEntity.status(201).body(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFeedback(@PathVariable Long id, Authentication authentication) {
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        feedbackService.deleteFeedback(id, principal);
        return ResponseEntity.noContent().build();
    }
}
