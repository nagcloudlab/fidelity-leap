package com.example.day3.p1;

public sealed interface Wheel  permits MRFWheel, CEATWheel {
    void rotate();
}
