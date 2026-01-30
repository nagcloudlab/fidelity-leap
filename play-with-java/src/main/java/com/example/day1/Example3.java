package com.example.day1;

import com.example.day1.util.Box;
import com.example.day1.util.LinkedList;

import java.util.Iterator;

public class Example3 {
    public static void main(String[] args) {

        LinkedList<String> list = new LinkedList<>();
        list.add("Apple");
        list.add("Banana");
        list.add("Cherry");

        String item = list.get(2);
        System.out.println("Item at index 2: " + item);

        System.out.println();

        // Traditional for loop to print all items
        System.out.println("All items in the list:");
//        for (int i = 0; i < list.size(); i++) {
//            System.out.println(list.get(i));
//        }

        Iterator<String> it = list.iterator();
        while (it.hasNext()) {
            System.out.println(it.next());
        }

        // java 1.5+ for-each loop
        System.out.println("All items in the list (using for-each):");
        for (String s : list) {
            System.out.println(s);
        }

        Box<String> box = new Box<>();
        box.add("item-1");
        box.add("item-2");

        for (String s : box) {
            System.out.println("Box contains: " + s);
        }


    }
}
