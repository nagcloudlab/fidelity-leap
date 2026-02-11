package com.example.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "feedbacks")
public class Feedback {
    @Id
    @GeneratedValue(strategy = jakarta.persistence.GenerationType.AUTO)
    private Long id;
    private String mood; // Happy, Sad, Neutral
    private int rating; // 1 to 5
    private String comment;
    @ManyToOne
    @JoinColumn(name = "user_id")
    @JsonIgnore
    private User user; // Assuming a feedback is associated with a user

}
