package com.example.day3;

import java.util.ArrayList;
import java.util.List;

import static java.util.Collections.sort;

public class NewFeatures_In_Java {
    public static void main(String[] args) {

        List<Integer> numbers = new ArrayList<>();
        numbers.add(5);
        numbers.add(2);
        numbers.add(8);
        numbers.add(1);
        sort(numbers);
        System.out.println("Sorted Numbers: " + numbers);

    }
}
