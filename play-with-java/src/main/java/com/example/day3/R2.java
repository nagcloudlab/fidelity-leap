package com.example.day3;

public class R2 {
    public synchronized void m1(R1 r1) {
        System.out.println("T2 having lock on R2");
        System.out.println("T2 trying to get lock on R1");
        r1.m2();
    }

    public synchronized void m2() {
        System.out.println("T1 also having lock on R2");
    }
}
