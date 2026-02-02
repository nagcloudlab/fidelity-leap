package com.example.day3;

public class Thread_Lifecycle_Example {
    public static void main(String[] args) {

        Runnable task = () -> {
            String threadName = Thread.currentThread().getName();
            System.out.println(threadName + " is in RUNNABLE state.");
            for (int i = 0; i < 1000; i++) {
                System.out.println(threadName + " - Count: " + i);
            }
            System.out.println(threadName + " is exiting RUNNABLE state.");
        };

        Thread fooThread = new Thread(task, "FooThread"); // NEW state
        Thread barThread = new Thread(task, "BarThread");
        Thread bazThread = new Thread(task, "BazThread");
        System.out.println(bazThread.getState());
        fooThread.start(); // New -> RUNNABLE
        barThread.start();
        bazThread.start();



    }
}
