package com.example.day3;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.ExecutorService;

public class Producer_Consumer_Pattern_Concurrent_Collection {
    public static void main(String[] args) {

        ArrayBlockingQueue <Integer> queue = new ArrayBlockingQueue<>(5);

        // produce task
        Runnable produceTask = () -> {
            int value = 0;
            try {
                while (true) {
                    System.out.println("Producing " + value);
                    queue.put(value++);
                    Thread.sleep(500);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        };

        // consume task
        Runnable consumeTask = () -> {
            try {
                while (true) {
                    Integer value = queue.take();
                    System.out.println("Consuming " + value);
                    Thread.sleep(1000);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        };

        // start producer and consumer threads
        ExecutorService  executor = java.util.concurrent.Executors.newFixedThreadPool(2);
        executor.submit(produceTask);
        executor.submit(consumeTask);


    }
}
