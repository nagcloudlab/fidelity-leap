package com.example.day1.model;

public class Apple {
    private String color;
    private double weight;
    public Apple(String color, double weight) {
        this.color = color;
        this.weight = weight;
    }
    public String getColor() {
        return color;
    }
    public double getWeight() {
        return weight;
    }
    // toString method for easy representation
    @Override
    public String toString() {
        return "Apple{" +
                "color='" + color + '\'' +
                ", weight=" + weight +
                '}';
    }
}
