package com.example.day2;

import java.util.List;
import java.util.stream.Stream;

public class Stream_Transform_Operations {
    public static void main(String[] args) {

//        .map()
        List<String> names= List.of("Alice", "Bob", "Charlie", "David");
        names.stream()
                .map(name->name.length())
                .forEach(length-> System.out.println(length));


        // .flatMap()
        List<String> foodMenu=List.of(
                "idly,vada,poori",
                "meals",
                "biriyani,pulao"
        );

        foodMenu
                .stream()
                .flatMap(line-> Stream.of(line.split(",")))
                .forEach(item-> System.out.println(item));


    }
}
