package com.example.day1.util;

// data-structure + iterator => iterable
// iterator => object who knows how to traverse a data-structure

import java.util.Iterator;

public class LinkedList<E> implements Iterable<E> {

    private Node head;
    private int size;

    public LinkedList() {
        this.head = null;
        this.size = 0;
    }

    @Override
    public Iterator<E> iterator() {
        Node current = head;
        return new Iterator<E>() {
            private Node node = current;

            @Override
            public boolean hasNext() {
                return node != null;
            }

            @Override
            public E next() {
                E data = node.data;
                node = node.next;
                return data;
            }
        };
    }

    public void add(E data) {
        Node newNode = new Node(data);
        if (head == null) {
            head = newNode;
        } else {
            Node current = head;
            while (current.next != null) {
                current = current.next;
            }
            current.next = newNode;
        }
        size++;
    }

    public int size() {
        return size;
    }

    public E get(int index) {
        if (index < 0 || index >= size) {
            throw new IndexOutOfBoundsException("Index: " + index + ", Size: " + size);
        }
        Node current = head;
        for (int i = 0; i < index; i++) {
            current = current.next;
        }
        return current.data;
    }


    private class Node {
        E data;
        Node next;

        Node(E data) {
            this.data = data;
            this.next = null;
        }

        public E getData() {
            return data;
        }

        public void setData(E data) {
            this.data = data;
        }

        public Node getNext() {
            return next;
        }

        public void setNext(Node next) {
            this.next = next;
        }
    }

}
