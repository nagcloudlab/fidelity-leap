package com.example.day2;

import java.util.List;

public class Stream_Sorting_Operation {

    public static void main(String[] args) {


        List<String> names = List.of("John", "Alice", "Bob", "Eve", "Charlie");
        names
                .stream()
                .sorted((n1, n2) -> n2.compareTo(n1))
                .forEach(name-> System.out.println(name));

    }

}
