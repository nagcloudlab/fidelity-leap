package com.example.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name="todos")
@Setter
@Getter
@Data
public class Todo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name="id")
    private Integer id;
    private String title;
    @Column(name="is_completed")
    private boolean completed;
    private String description;
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
    @Enumerated(EnumType.STRING)
    private TodoType todoType;
    @ManyToOne(fetch = FetchType.EAGER,targetEntity = User.class)
    @JoinColumn(name="user_id")
    private User user;


}
