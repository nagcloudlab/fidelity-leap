package com.example.day3;

import java.util.Scanner;

public class App2 {
    public static void main(String[] args) {

        Runnable computationTask = () -> {
            String threadName = Thread.currentThread().getName();
            System.out.println("Computation started in thread: " + threadName);
            long sum = 0;
            for (long i = 1; i <= 1_000_000_00_00L; i++) {
                sum += i;
            }
            System.out.println("Sum computed in thread " + threadName + ": " + sum);
        };

        Runnable ioTask = () -> {
            String threadName = Thread.currentThread().getName();
            System.out.println("I/O operation started in thread: " + threadName);
            Scanner scanner = new Scanner(System.in);
            System.out.print("Enter some input: ");
            String userInput = scanner.nextLine();
            System.out.println("You entered: " + userInput);
            System.out.println("I/O operation completed in thread: " + threadName);
        };

        Thread ioThread = new Thread(ioTask);
        ioThread.start(); // allocates new-stack memory for the new thread

        Thread computationThread = new Thread(computationTask);
        computationThread.start(); // allocates new-stack memory for the new thread

    }
}
