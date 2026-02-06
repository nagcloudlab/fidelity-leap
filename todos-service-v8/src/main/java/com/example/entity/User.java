package com.example.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name="users")
@Getter
@Setter
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    private String username;
    private String email;
    @Column(name = "password_hash")
    private String password;
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    @Column(name = "todos_count")
    private int todosCount;

    //@OneToMany(mappedBy = "user",targetEntity = Todo.class)
    //private List<Todo> todos;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "user_roles",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    private List<Role> roles;



}
