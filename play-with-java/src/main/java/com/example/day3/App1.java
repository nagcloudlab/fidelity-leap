package com.example.day3;

import java.util.Scanner;

public class App1 {
    public static void main(String[] args) {
        String threadName = Thread.currentThread().getName();
        System.out.println("Hello from " + threadName);

        // step-1: io
        io();
        // step-2: computation
        computation();

    }

    private static void computation() {
        String threadName = Thread.currentThread().getName();
        System.out.println("thread " + threadName + " is doing computation...");
        while (true) {
            // infinite loop to simulate computation
        }
        //System.out.println("thread " + threadName + " has completed computation.");
    }

    private static void io() {
        String threadName = Thread.currentThread().getName();
        System.out.println("thread " + threadName + " is doing io...");
        Scanner scanner = new Scanner(System.in);
        System.out.print("Enter something: ");
        String input = scanner.nextLine();
        System.out.println("You entered: " + input);
        System.out.println("thread " + threadName + " has completed io.");
    }
}
