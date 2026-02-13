package com.example.orderservice.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Data
@Entity
public class Product {
    @Id
    private Long id;
    private String name;
    private String category;
    private String brand;
    private double price;
    private String description;
    private boolean active;
}
