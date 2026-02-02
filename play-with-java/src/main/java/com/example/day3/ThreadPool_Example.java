package com.example.day3;

// java 1.5+

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

public class ThreadPool_Example {
    public static void main(String[] args) {


        ExecutorService threadPool = Executors.newFixedThreadPool(2);

        Runnable task = () -> {
            String threadName = Thread.currentThread().getName();
            System.out.println("Task started by: " + threadName);
            try {
                Thread.sleep(2000); // Simulate work
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            System.out.println("Task completed by: " + threadName);
        };

        threadPool.submit(task);
        threadPool.submit(task);
        threadPool.submit(task);
        threadPool.submit(task);
        threadPool.submit(task);


    }
}
