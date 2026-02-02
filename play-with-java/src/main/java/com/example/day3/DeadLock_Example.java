package com.example.day3;


public class DeadLock_Example {
    public static void main(String[] args) {

        R1 r1 = new R1();
        R2 r2 = new R2();

        Thread t1 = new Thread(() -> {
            r1.m1(r2);
        });
        Thread t2 = new Thread(() -> {
            r2.m1(r1);
        });

        t1.start();
        t2.start();

    }
}
