package com.example.day1.util;

import java.util.Iterator;

public class Box<E>  implements Iterable<E>{
    private Object[] elements;
    private int size;
    private static final int DEFAULT_CAPACITY = 10;

    public Box() {
        elements = new Object[DEFAULT_CAPACITY];
        size = 0;
    }

    public void add(E element) {
        if (size == elements.length) {
            //  resize();
        }
        elements[size++] = element;
    }

    @SuppressWarnings("unchecked")
    public E get(int index) {
        if (index < 0 || index >= size) {
            throw new IndexOutOfBoundsException("Index: " + index + ", Size: "
                    + size);
        }
        return (E) elements[index];
    }

    @Override
    public Iterator<E> iterator() {
        return new Iterator<E>() {
            private int currentIndex = 0;

            @Override
            public boolean hasNext() {
                return currentIndex < size;
            }

            @SuppressWarnings("unchecked")
            @Override
            public E next() {
                return (E) elements[currentIndex++];
            }
        };
    }
}
