package com.example.day2;

import com.example.day2.model.Account;

import java.util.List;

public class Stream_Filter_Operations {
    public static void main(String[] args) {

        /*

            content based filtering
                - filter(Predicate<T>)  --> Stream<T>
                - takeWhile(Predicate<T>) --> Stream<T>
                - dropWhile(Predicate<T>) --> Stream<T>

            count based filtering
                - limit(long n)  --> Stream<T>
                - skip(long n)   --> Stream<T>

            Uniqueness  filtering
                - distinct()  --> Stream<T>


         */


        // content based filtering

        List<Account> accounts = List.of(
                new Account("A101", "A", 1000),
                new Account("A102", "B", 2000),
                new Account("A103", "C", 3000),
                new Account("A104", "D", 4000),
                new Account("A105", "E", 5000)
        );


        // a. filter
        accounts
                .stream()
                .filter(account -> account.getBalance() < 4000)
                .forEach(System.out::println);

        System.out.println("---------------------");

        // a. takeWhile -> stops processing as soon as the predicate fails
        // b. dropWhile -> skips elements as long as the predicate is true, then processes the rest

        accounts
                .stream()
                .takeWhile(account -> account.getBalance() < 4000)
                .forEach(System.out::println);

        System.out.println("---------------------");

        accounts
                .stream()
                .dropWhile(account -> account.getBalance() < 3000)
                .forEach(System.out::println);

        //------------------------

        // count based filtering
        System.out.println("---------------------");

        accounts
                .stream()
                .limit(3)
                .forEach(System.out::println);


        System.out.println("---------------------");

        accounts
                .stream()
                .skip(2)
                .forEach(System.out::println);

        // uniqueness filtering
        System.out.println("---------------------");

        List<Account> accountsWithDuplicates = List.of(
                new Account("A101", "A", 1000),
                new Account("A102", "B", 2000),
                new Account("A103", "C", 3000),
                new Account("A101", "A", 1000),
                new Account("A104", "D", 4000),
                new Account("A102", "B", 2000),
                new Account("A105", "E", 5000)
        );

        accountsWithDuplicates
                .stream()
                .distinct()
                .forEach(System.out::println);

    }
}
