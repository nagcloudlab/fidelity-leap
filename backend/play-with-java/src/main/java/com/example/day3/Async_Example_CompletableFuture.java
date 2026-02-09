package com.example.day3;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;

public class Async_Example_CompletableFuture {
    public static void main(String[] args) {

        ExecutorService pool1 = java.util.concurrent.Executors.newFixedThreadPool(3);
        ExecutorService pool2 = java.util.concurrent.Executors.newFixedThreadPool(5);

        // team-1
        CompletableFuture.supplyAsync(() -> {
                    try {
                        Thread.sleep(2000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                    return 10;
                }, pool1)
                // team-2
                .thenApplyAsync((num) -> {
                    return num * 10;
                }, pool2)
                // team-3
                .thenAccept(result -> {
                    System.out.println("Final Result: " + result);
                });

        // Reactive Extensions (RxJava, Reactor)

    }
}
