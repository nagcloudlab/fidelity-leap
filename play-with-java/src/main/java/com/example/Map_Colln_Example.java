package com.example;

import java.util.Objects;
import java.util.Scanner;

class Owner {
    String name;
    int age;

    Owner(String name, int age) {
        this.name = name;
        this.age = age;
    }

    // toString method
    @Override
    public String toString() {
        return "Owner{name='" + name + "', age=" + age + "}";
    }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof Owner owner)) return false;
        return Objects.equals(name, owner.name);
    }

    @Override
    public int hashCode() {
        return Objects.hashCode(name);
    }
}
class Car{
    String model;
    String color;

    Car(String model, String color) {
        this.model = model;
        this.color = color;
    }

    // toString method
    @Override
    public String toString() {
        return "Car{model='" + model + "', color='" + color + "'}";
    }
}

public class Map_Colln_Example {
    public static void main(String[] args) {

        Owner owner1 = new Owner("Alice", 30);
        Owner owner2 = new Owner("Bob", 45);

        Car car1 = new Car("Toyota", "Red");
        Car car2 = new Car("Honda", "Blue");

        java.util.Map<Owner, Car> ownerCarMap = new java.util.HashMap<>();
        ownerCarMap.put(owner1, car1);
        ownerCarMap.put(owner2, car2);

        //-------------------------------------------------

        Scanner scanner = new Scanner(System.in);
        System.out.print("Enter owner name to search: ");
        String searchName = scanner.nextLine();
        Owner keyOwner=new Owner(searchName,0); // age is not relevant for search

        Car ownedCar = ownerCarMap.get(keyOwner);

        if (ownedCar != null) {
            System.out.println("Car owned by " + searchName + ": " + ownedCar);
        } else {
            System.out.println(searchName + " does not own a car in the records.");
        }

        //-------------------------------------------------


    }
}
