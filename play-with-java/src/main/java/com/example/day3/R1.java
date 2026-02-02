package com.example.day3;

public class R1 {
    public synchronized void m1(R2 r2) {
        System.out.println("T1 having lock on R1");
        System.out.println("T1 trying to get lock on R2");
        r2.m2();
    }

    public synchronized void m2() {
        System.out.println("T2 also having lock on R1");
    }
}
