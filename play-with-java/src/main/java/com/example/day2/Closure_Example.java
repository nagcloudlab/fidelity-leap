package com.example.day2;

import java.util.function.Supplier;

public class Closure_Example {
    public static void main(String[] args) {

        int count = 0;

        Supplier<Integer> supplier = () -> {
            return count;
        };

        System.out.println("Count: " + supplier.get());

    }
}
