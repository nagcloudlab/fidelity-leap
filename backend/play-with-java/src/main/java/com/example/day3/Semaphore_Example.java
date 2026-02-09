package com.example.day3;

import java.util.concurrent.Semaphore;

public class Semaphore_Example {
    public static void main(String[] args) {

        Semaphore semaphore = new Semaphore(2); // Allow 2 permits

        Runnable task = () -> {
            String threadName = Thread.currentThread().getName();
            try {
                System.out.println(threadName + " is trying to acquire a permit.");
                semaphore.acquire();
                System.out.println(threadName + " has acquired a permit.");

                // Simulate some work with the resource
                Thread.sleep(2000);

                System.out.println(threadName + " is releasing the permit.");
            } catch (InterruptedException e) {
                e.printStackTrace();
            } finally {
                semaphore.release();
            }
        };

    }
}
