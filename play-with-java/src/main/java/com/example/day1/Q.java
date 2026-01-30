package com.example.day1;

import java.util.List;

public class Q {
    public static void main(String[] args) {


        List<String> menu = List.of("veg", "veg", "non-veg", "veg", "veg");

        // replace non-veg with 'Nil'

        menu.replaceAll(item -> item.equals("non-veg") ? "Nil" : item);
        System.out.println(menu);


    }
}
