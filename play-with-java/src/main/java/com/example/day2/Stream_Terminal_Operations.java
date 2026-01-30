package com.example.day2;

import com.example.day2.model.Dish;

import java.util.IntSummaryStatistics;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

public class Stream_Terminal_Operations {

    public static void main(String[] args) {


        List<Dish> menu = Dish.getSampleMenu();

        // void terminal operations
        menu.stream()
                .filter(dish -> dish.getCalories() > 300)
                .forEach(dish -> System.out.println(dish.getName()));

        // boolean terminal operations
        boolean hasHealthyDish = menu.stream()
//                .anyMatch(dish -> dish.getCalories() < 200);
//        .allMatch(dish -> dish.getCalories() < 1000);
                .noneMatch(dish -> dish.getCalories() >= 1000);
        System.out.println("Is there any healthy dish? " + hasHealthyDish);

        // Optional<T> terminal operations

        List<Integer> numbers = List.of(3, 5, 7, 2, 8, 10);

        Optional<Integer> op = numbers
                .stream()
                .filter(n -> n % 2 == 0)
                .findFirst();

        if (op.isPresent()) {
            System.out.println("First even number: " + op.get());
        } else {
            System.out.println("No even number found.");
        }

        //--------------------------------------------
        // collect terminal operation
        //--------------------------------------------

        // .toList
        System.out.println(
         menu.stream()
                .filter(dish -> dish.getCalories() > 300)
                .collect(Collectors.toList())
        );

        // .toSet
        System.out.println(
         menu.stream()
                .filter(dish -> dish.getCalories() > 300)
                .collect(Collectors.toSet())
        );

        // .toMap
        System.out.println(
         menu.stream()
                .filter(dish -> dish.getCalories() > 300)
                .collect(Collectors.toMap(Dish::getName, Dish::getCalories))
        );

        // joining
        String dishNames = menu.stream()
                .map(Dish::getName)
                .collect(Collectors.joining(", ", "[", "]"));
        System.out.println(dishNames);

        // summarizing
        IntSummaryStatistics stats = menu.stream()
                .collect(Collectors.summarizingInt(Dish::getCalories));
        System.out.println("Max calories: " + stats.getMax());
        System.out.println("Min calories: " + stats.getMin());
        System.out.println("Average calories: " + stats.getAverage());
        System.out.println("Total calories: " + stats.getSum());

        // counting
        long count = menu.stream()
                .filter(dish -> dish.getCalories() > 300)
                .collect(Collectors.counting());
        System.out.println("Number of dishes with more than 300 calories: " + count);

        // partitioningBy
        Map<Boolean,List<Dish>> partitionedMenu = menu.stream()
                .collect(Collectors.partitioningBy(dish -> dish.getCalories() > 500));
        System.out.println("Dishes partitioned by calories > 500: " + partitionedMenu);

        // groupingBy
        Map<Dish.Type, List<Dish>> groupedMenu = menu.stream()
                .collect(Collectors.groupingBy(Dish::getType));
        System.out.println("Dishes grouped by type: " + groupedMenu);


    }

}
