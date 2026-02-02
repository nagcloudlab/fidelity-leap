package com.example.day3;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.List;
import java.util.concurrent.*;

public class Async_Example_With_Future {
    public static void main(String[] args) {


        // Main thread

        Callable<List<String>> readFileTask = () -> {
            FileReader fileReader = new FileReader("menu.txt");
            TimeUnit.SECONDS.sleep(5);
            BufferedReader bufferedReader = new BufferedReader(fileReader);
            List<String> lines = bufferedReader.lines().toList();
            bufferedReader.close();
            return lines;
        };

//        try {
//            List<String> lines = readFileTask.call();
//            System.out.println("File read complete. Number of lines: " + lines.size());
//        } catch (Exception e) {
//            throw new RuntimeException(e);
//        }

        ExecutorService executorService = java.util.concurrent.Executors.newFixedThreadPool(1);
        Future<List<String>> future = executorService.submit(readFileTask);

        System.out.println("Main thread is free to do other work while file is being read asynchronously.");

        try {
            List<String> lines = future.get();
            System.out.println("File read complete. Number of lines: " + lines.size());
            executorService.shutdown();
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException(e);
        }

    }
}


// java 1.8 : CompletableFuture