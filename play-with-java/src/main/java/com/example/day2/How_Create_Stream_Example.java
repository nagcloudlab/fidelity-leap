package com.example.day2;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;

public class How_Create_Stream_Example {
    public static void main(String[] args) throws IOException {


        // finite streams
        //------------------
        // way-1: from values
        Stream<String> stream1 = Stream.of("A", "B", "C", "D");

        // way-2: from array
        String[] arr = {"E", "F", "G", "H"};
        Stream<String> stream2 = Stream.of(arr);

        // way-3: from collection
        var list = java.util.List.of("I", "J", "K", "L");
        Stream<String> stream3 = list.stream();

        // infinite streams
        //------------------
        // way-1: using Stream.generate()
        Stream<Double> infiniteStream1 = Stream.generate(() -> {
            return Math.random();
        });
        // way-2: using Stream.iterate()
        Stream<Integer> infiniteStream2 = Stream.iterate(1, n -> n + 1);

        // ------------------------------------------------------------
        // way-1 : from file source
        Stream<String> fileStream = Files.lines(Path.of("path/to/file.txt"));


    }
}
