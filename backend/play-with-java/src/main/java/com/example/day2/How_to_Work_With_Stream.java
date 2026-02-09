package com.example.day2;

import java.util.List;
import java.util.Random;
import java.util.stream.Stream;

public class How_to_Work_With_Stream {

    public static void main(String[] args) {

        // step-1 : create stream from data-source ( collection, array, file, etc. ) -> reads
        // step-2 : apply intermediate operations ( filter, map, sorted, etc. ) -> process
        // step-3 : apply terminal operation ( forEach, collect, reduce, etc. ) -> collect result

        //------------------------------------------------------

        List<Integer> numbers = List.of(10, -5, 0, 15, -20, 25, 30);
        // step-1: create stream
        Stream<Integer> stream = numbers.stream()
                // step-2: intermediate operations
                .peek(n -> System.out.println("before filter: " + n))
                .filter(n -> n > 0)
                .peek(n -> System.out.println("after filter: " + n))
                // step-3: terminal operation
                .limit(3)
                .peek(n -> System.out.println("after limit: " + n));
//                .forEach(n -> {
//                    System.out.println("Final Output: " + n);
//                });


        stream
                .forEach(n -> {
                    System.out.println("Final Output: " + n);
                });

//        stream
//                .forEach(n -> {
//                    System.out.println("Final Output Again: " + n);
//                });

    }
}
