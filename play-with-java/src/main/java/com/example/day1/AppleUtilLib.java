package com.example.day1;

import com.example.day1.model.Apple;

import java.util.List;
import java.util.function.Predicate;

public class AppleUtilLib {


    // author : Nag
    public static List<Apple> filterApples(List<Apple> inventory, Predicate<Apple> predicate) {
        List<Apple> result = new java.util.ArrayList<>();
        for (Apple apple : inventory) {
            if (predicate.test(apple)) {
                result.add(apple);
            }
        }
        return result;
    }

    public static List<Apple> filterApplesByWeight(List<Apple> inventory, int weight) {
        List<Apple> result = new java.util.ArrayList<>();
        for (Apple apple : inventory) {
            if (apple.getWeight() > weight) {
                result.add(apple);
            }
        }
        return result;
    }
    public static List<Apple> filterApplesByColor(List<Apple> inventory, String color) {
        List<Apple> result = new java.util.ArrayList<>();
        for (Apple apple : inventory) {
            if (color.equals(apple.getColor())) {
                result.add(apple);
            }
        }
        return result;
    }
    public static List<Apple> filterGreenApples(List<Apple> inventory) {
        List<Apple> result = new java.util.ArrayList<>();
        for (Apple apple : inventory) {
            if ("green".equals(apple.getColor())) {
                result.add(apple);
            }
        }
        return result;
    }
    public static List<Apple> filterRedApples(List<Apple> inventory) {
        List<Apple> result = new java.util.ArrayList<>();
        for (Apple apple : inventory) {
            if ("red".equals(apple.getColor())) {
                result.add(apple);
            }
        }
        return result;
    }

}
