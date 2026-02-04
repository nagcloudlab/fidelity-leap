package com.example.aspect;

public class TransactionManager {

    public void begin(){
        System.out.println("Transaction started.");
    }

    public void commit(){
        System.out.println("Transaction ended.");
    }

    public void rollback(){
        System.out.println("Transaction rolled back.");
    }

}
