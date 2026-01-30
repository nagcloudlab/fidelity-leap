package com.example.day2;

import com.example.day2.model.Account;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class List_Sorting_Example {
    public static void main(String[] args) {

        List<Account> accounts = new ArrayList<>();
        accounts.add(new Account("101", "Alice", 5000));
        accounts.add(new Account("103", "Charlie", 7000));
        accounts.add(new Account("102", "Bob", 3000));
        accounts.add(new Account("104", "Bob", 8000));

        displayAccounts(accounts);

        // Sort by account number (String)
        // sorting by natural property ( balanace ) defined in Comparable interface
       // Collections.sort(accounts);

        System.out.println("-".repeat(30));
        displayAccounts(accounts);

        // Sort by account holder name (String)

        Comparator<Account> nameComparatorAsc = (a1, a2) -> a1.getAccountHolder().compareTo(a2.getAccountHolder());
        //Comparator<Account> nameComparatorDsc = (a1, a2) -> a2.getAccountHolder().compareTo(a1.getAccountHolder());
       // Comparator<Account> nameComparatorDsc = Comparator.reverseOrder();
        Comparator<Account> balanceComparator = (a1, a2) -> Double.compare(a1.getBalance(), a2.getBalance());
        Comparator<Account> nameThenBalanceComparator = nameComparatorAsc.thenComparing(balanceComparator);

        Comparator<Account> idComparator = Comparator.comparing(Account::getAccountNumber);

        Collections.sort(accounts, idComparator);
        System.out.println("-".repeat(30));
        displayAccounts(accounts);

    }

    private static void displayAccounts(List<Account> accounts) {
        System.out.println("Accounts:");
        for (Account account : accounts) {
            System.out.println(account);
        }
    }


}
