package com.example.day1;

import com.example.day1.model.Apple;

import java.util.List;
import java.util.function.Predicate;

public class Example1 {
    public static void main(String[] args) {

        List<Apple> inventory = List.of(
                new Apple("green", 150),
                new Apple("red", 120),
                new Apple("green", 170)
        );

        //----------------------------------------------
        // Req-1: filter green apples
        //----------------------------------------------
        // You
        //List<Apple> output = AppleUtilLib.filterGreenApples(inventory);
        //List<Apple> output = AppleUtilLib.filterApplesByColor("green");
        List<Apple> output = AppleUtilLib.filterApples(inventory, new GreenApplePredicate());
        System.out.println("Green Apples: " + output);

        //----------------------------------------------
        // Req-2: filter red apples
        //----------------------------------------------
        output = AppleUtilLib.filterApples(inventory, new Predicate<Apple>() {
            @Override
            public boolean test(Apple apple) {
                return "red".equals(apple.getColor());
            }
        });
        System.out.println("Red Apples: " + output);

        //----------------------------------------------
        // Req-3: filter apples by weight
        //----------------------------------------------
        // From Java-8, we can use Lambda expression aka function
        output = AppleUtilLib.filterApples(inventory, apple -> apple.getWeight() == 150);
        System.out.println("150g Apples: " + output);

        //----------------------------------------------
        // Req-4: filter apples by any criteria
        //----------------------------------------------


    }
}
