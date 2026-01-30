package com.example.day2;

import java.util.ArrayList;
import java.util.List;


class FoodLib {
    private static List<String> nonVegItems = List.of("c-biriyani", "mutton-chops", "chicken-fry", "fish-curry");

    public static boolean isNonVeg(String item) {
        return nonVegItems.contains(item);
    }
}

public class MethodReference_Example {
    public static void main(String[] args) {

        List<String> menu = new ArrayList<>();
        menu.add("idli");
        menu.add("dosa");
        menu.add("c-biriyani");
        menu.add("vada");
        menu.add("puri");

        menu.removeIf(FoodLib::isNonVeg); // method reference to static method
        System.out.println("Veg Menu: " + menu);

    }
}
