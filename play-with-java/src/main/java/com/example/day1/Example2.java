package com.example.day1;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class Example2 {
    public static void main(String[] args) {

        List<String> menu = new ArrayList<>();
        menu.add("veg");
        menu.add("non-veg");
        menu.add("veg");
        menu.add("veg");
        menu.add("non-veg");

        // remove all non-veg items from the menu by mutating the original list
        // way-1: imperative approach ( traditional for loop )
//        for(int i=0;i<menu.size();i++) {
//            if (menu.get(i).equals("non-veg")) {
//                menu.remove(i);
//                i--; // adjust index after removal
//            }
//        }
//        System.out.println("Menu after removing non-veg items (imperative): " + menu);
        // way-2: traditional for-each loop ( this will throw ConcurrentModificationException )`
//        for (String item : menu) {
//            if (item.equals("non-veg")) {
//                menu.remove(item); // this will throw ConcurrentModificationException
//            }
//        }
//        System.out.println("Menu after removing non-veg items (for-each): " + menu);

        //
        Iterator<String> iterator = menu.iterator();
        while (iterator.hasNext()) {
            String item = iterator.next();
            if (item.equals("non-veg")) {
                iterator.remove();
            }
        }
        System.out.println("Menu after removing non-veg items (using iterator): " + menu);

        menu.removeIf(item-> item.equals("non-veg"));

    }
}
