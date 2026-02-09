package com.example.day1;

import com.example.day1.model.Apple;

import java.util.function.Predicate;

public class GreenApplePredicate implements Predicate<Apple> {
    @Override
    public boolean test(Apple apple) {
        return "green".equalsIgnoreCase(apple.getColor());
    }
}
