package com.example.day2;

import com.example.day2.model.Account;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;
import java.util.Vector;

public class List_Colln_Example {

    public static void main(String[] args) {

        compare(new Vector<>(1_000_000));
        compare(new ArrayList<>(1_000_000));
        compare(new LinkedList<>());


    }

    private static void compare(List<Account> accounts) {
        long start = System.nanoTime();

        // add 1M accounts
        for (int i = 0; i < 1_000_000; i++) {
            accounts.add(new Account(String.valueOf(i), "Account-" + i, i * 1000.0));
        }

        long end = System.nanoTime();
        System.out.println("Time taken: " + (end - start) + " ns");
    }

}
