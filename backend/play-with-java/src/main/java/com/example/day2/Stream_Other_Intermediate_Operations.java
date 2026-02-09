package com.example.day2;

import com.example.day2.model.Account;

import java.util.List;

public class Stream_Other_Intermediate_Operations {
    public static void main(String[] args) {


        //
        List<Account> accounts = List.of(
                new Account("A1", "A", 1000.0),
                new Account("A2", "B", 2000.0),
                new Account("A3", "A", 3000.0),
                new Account("A4", "C", 4000.0)
        );

        System.out.println(
        accounts
                .stream()
                .mapToDouble(account-> account.getBalance())
                .sum()
        );


    }
}
