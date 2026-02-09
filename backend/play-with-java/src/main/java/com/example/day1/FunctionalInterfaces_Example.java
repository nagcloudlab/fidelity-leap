package com.example.day1;

import java.util.List;
import java.util.function.*;

public class FunctionalInterfaces_Example {
    public static void main(String[] args) {


        // input -> boolean
        Predicate<Integer> isEven = number -> number % 2 == 0;
        boolean b = isEven.test(12);

        // any-input -> any-output
        Function<String, Integer> stringLength = str -> str.length();
        int length = stringLength.apply("Hello");

        // no-input -> any-output
        Supplier<Double> randomValue = () -> Math.random();

        // any-input -> no-output
        Consumer<String> printMessage = message -> System.out.println(message);
        printMessage.accept("Hello, World!");

        //------------------------------------------------------------
        BiPredicate<Integer, Integer> isGreater = (a, bb) -> a > bb;
        boolean result1 = isGreater.test(10, 5);

        BiFunction<String, String, String> concatenate = (str1, str2) -> str1 + str2;
        String result2 = concatenate.apply("Hello, ", "World!");

        BiConsumer<String, Integer> printNameAndAge = (name, age) ->
                System.out.println("Name: " + name + ", Age: " + age);
        printNameAndAge.accept("Alice", 30);

        //------------------------------------------------------------

        UnaryOperator<Integer> square = x -> x * x;
        BinaryOperator<Integer> add = (a, b1) -> a + b1;

        //------------------------------------------------------------

        // Imp Q, is java is pure object-oriented?

        int i = 10; // primitive data type

        //

        List<Integer> list = List.of(1, 2, 3, 4, 5); // autoboxing

        //------------------------------------------------------------

        BiFunction<Integer,Integer,Integer> addd = (a1,b1) -> a1 * b1;
        int res = addd.apply(3,4);
        System.out.println(res);

        //------------------------------------------------------------

        IntBinaryOperator intAdd = (x1, y1) -> x1 + y1;
        int intResult = intAdd.applyAsInt(5, 10);
        System.out.println(intResult);

    }
}
