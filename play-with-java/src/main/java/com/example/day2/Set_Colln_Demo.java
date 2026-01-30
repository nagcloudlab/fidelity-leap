package com.example.day2;

import com.example.day2.model.Account;

import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.TreeSet;

public class Set_Colln_Demo {
    public static void main(String[] args) {


        Account a1 = new Account("A001", "John Doe", 1000.0);
        Account a2 = new Account("A002", "John Doe", 2000.0);
        Account a3 = new Account("A001", "John Doe", 1500.0);
        Account a4 = new Account("A003", "Jane Smith", 3000.0);
        Account a5 = new Account("A004", "John Doe", 2000.0);


//        System.out.println(a1.hashCode());
//        System.out.println(a2.hashCode());
//        System.out.println(a1.equals(a2));


//        Set<Account> accounts = new HashSet<>();
        //Set<Account> accounts = new LinkedHashSet<>();
        Set<Account> accounts = new TreeSet<>((acc1, acc2) -> {
            if (acc1.getBalance() == acc2.getBalance()) return 0;
            else if (acc1.getBalance() > acc2.getBalance()) return 1;
            else return -1;
        });
        accounts.add(a1);
        accounts.add(a2);
        accounts.add(a3);
        accounts.add(a4);
        accounts.add(a5);

        for (Account acc : accounts) {
            System.out.println(acc);
        }

    }
}
