package com.example;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;


@Data
@AllArgsConstructor
@NoArgsConstructor
class Review {
    private int id;
    private int stars;
    private String author;
    private String body;
}

@Data
@AllArgsConstructor
@NoArgsConstructor
class Product {
    private int id;
    private String name;
    private double price;
    private String currencyCode;
    private String description;
    private String imageUrl;
    private String category;
    private LocalDateTime makeDate;
}


// Repository
// Service
// Controller

@RestController
@RequestMapping("/api/v1/products")
@CrossOrigin({
        "http://localhost:4200"
})
class ProductController {
    private static List<Product> products = List.of(
            new Product(1, "Laptop", 190000.99, "INR", "Description of Product 1", "/Laptop.png", "electronics", LocalDateTime.now()),
            new Product(2, "Smartphone", 50000.00, "INR", "Description of Product 2", "/Mobile.png", "electronics", LocalDateTime.now())
            );
    private static Map<Integer, List<Review>> reviews = Map.of(
            1, List.of(
                    new Review(1, 5, "Alice", "Great laptop!"),
                    new Review(2, 4, "Bob", "Good value for money.")
            ),
            2, List.of(
                    new Review(3, 4, "Charlie", "Nice smartphone."),
                    new Review(4, 3, "Dave", "Battery life could be better.")
            )
    );


    @GetMapping
    public List<Product> getAllProducts() {
        return products;
    }

    @GetMapping("/{id}/reviews")
    public List<Review> getReviewsByProductId(@PathVariable int id) {
        return reviews.getOrDefault(id, List.of());
    }

}


@SpringBootApplication
public class ProductServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(ProductServiceApplication.class, args);
    }

}
