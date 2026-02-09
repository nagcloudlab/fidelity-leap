package com.example.day3;

import java.util.concurrent.TimeUnit;

public class Wait_Notify_Example {

    final static Object lock = new Object();
    static boolean foodAvailable = false;

    public static void main(String[] args) {


        Runnable eatFood = () -> {
            String threadName = Thread.currentThread().getName();
            System.out.println(threadName + " is trying to eat food");
            synchronized (lock) {
                if (!foodAvailable) {
                    System.out.println(threadName + " didn't find food and is waiting");
                    try {
                        lock.wait();
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
        };

        Runnable cookFood = () -> {
            String threadName = Thread.currentThread().getName();
            System.out.println(threadName + " is cooking food");
            synchronized (lock) {
                foodAvailable = true;
                try {
                    TimeUnit.SECONDS.sleep(10);
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                }
                System.out.println(threadName + " has cooked the food and is notifying waiting threads");
                lock.notifyAll();
            }
        };

        Thread eaterThread = new Thread(eatFood, "EaterThread");
        Thread cookThread = new Thread(cookFood, "CookThread");
        eaterThread.start();
        cookThread.start();

    }
}
