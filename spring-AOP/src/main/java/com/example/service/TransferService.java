package com.example.service;

import org.springframework.stereotype.Component;

/*

    Unit Of Execution with SQL databases => Transaction
    - contains more than one database operation ( insert, update, delete)

    must satisfy ACID properties

    A - Atomicity -> all or nothing

 */

@Component
public class TransferService {
    // joinpoint
    public void transfer(){
        System.out.println("TransferService: Performing transfer operation.");
        throw  new RuntimeException("Simulated exception during transfer.");
    }
}
