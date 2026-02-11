package com.example.service;

import com.example.dto.FeedbackRequestDto;
import com.example.dto.FeedbackResponseDto;
import com.example.entity.Feedback;
import com.example.entity.User;
import com.example.exception.ResourceNotFoundException;
import com.example.repository.FeedbackRepository;
import com.example.repository.UserRepository;
import com.example.security.UserPrincipal;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class FeedbackService {

    private final FeedbackRepository feedbackRepository;
    private final UserRepository userRepository;

    public FeedbackService(FeedbackRepository feedbackRepository, UserRepository userRepository) {
        this.feedbackRepository = feedbackRepository;
        this.userRepository = userRepository;
    }

    public List<FeedbackResponseDto> getAllFeedbacks(UserPrincipal principal) {
        List<Feedback> feedbacks;
        if ("ADMIN".equals(principal.role())) {
            feedbacks = feedbackRepository.findAll();
        } else {
            feedbacks = feedbackRepository.findByUserId(principal.id());
        }

        return feedbacks.stream()
                .map(this::toResponseDto)
                .toList();
    }

    @Transactional
    public FeedbackResponseDto createFeedback(FeedbackRequestDto dto, UserPrincipal principal) {
        User user = userRepository.getReferenceById(principal.id());

        Feedback feedback = new Feedback();
        feedback.setMood(dto.getMood());
        feedback.setRating(dto.getRating());
        feedback.setComment(dto.getComment());
        feedback.setUser(user);

        Feedback saved = feedbackRepository.save(feedback);
        return new FeedbackResponseDto(
                saved.getId(),
                saved.getMood(),
                saved.getRating(),
                saved.getComment(),
                saved.getCreatedAt(),
                principal.username()
        );
    }

    @Transactional
    public void deleteFeedback(Long id, UserPrincipal principal) {
        if (!"ADMIN".equals(principal.role())) {
            throw new AccessDeniedException("Only admin can delete feedback");
        }

        if (!feedbackRepository.existsById(id)) {
            throw new ResourceNotFoundException("Feedback not found with id: " + id);
        }

        feedbackRepository.deleteById(id);
    }

    private FeedbackResponseDto toResponseDto(Feedback feedback) {
        return new FeedbackResponseDto(
                feedback.getId(),
                feedback.getMood(),
                feedback.getRating(),
                feedback.getComment(),
                feedback.getCreatedAt(),
                feedback.getUser() != null ? feedback.getUser().getUsername() : null
        );
    }
}
