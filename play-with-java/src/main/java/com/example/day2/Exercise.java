package com.example.day2;

import com.example.day2.model.Dish;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/*

    data processing pipeline

        -> filtering
        -> mapping aka transformation
        -> sorting
        -> min/max
        .....

        solution: streams API (Java-8)

 */


public class Exercise {

    public static void main(String[] args) {

        List<Dish> menu = Dish.getSampleMenu();

        // get low calorie dish names ( < 400 calories ), sorted by calories
        List<String> lowCalorieDishNames = getLowCalorieDishNamesV1(menu);
        System.out.println("Low calorie dish names: " + lowCalorieDishNames);
        lowCalorieDishNames = getLowCalorieDishNamesV2(menu);
        System.out.println("Low calorie dish names: " + lowCalorieDishNames);

    }

    private static List<String> getLowCalorieDishNamesV2(List<Dish> menu) {
        return menu
                .stream()
                .filter(dish -> dish.getCalories() < 400)
                .sorted(Comparator.comparingInt(Dish::getCalories))
                .map(Dish::getName)
                .toList();
    }

    // problems with this approach:
    // 1. verbose
    // 2. hard to read
    // 3. hard to maintain on concurrent scenarios
    private static List<String> getLowCalorieDishNamesV1(List<Dish> menu) {
        // step-1: filter
        List<Dish> lowCalorieDishes = new ArrayList<>();
        for (Dish dish : menu) {
            if (dish.getCalories() < 400) {
                lowCalorieDishes.add(dish);
            }
        }
        // step-2: sort
        lowCalorieDishes.sort(new Comparator<Dish>() {
            @Override
            public int compare(Dish o1, Dish o2) {
                return Integer.compare(o1.getCalories(), o2.getCalories());
            }
        });
        // step-3: map
        List<String> lowCalorieDishNames = new ArrayList<>();
        for (Dish dish : lowCalorieDishes) {
            lowCalorieDishNames.add(dish.getName());
        }
        return lowCalorieDishNames;
    }

}
