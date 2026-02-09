package com.example.day2;

import java.util.Optional;

class Insurance {
    String name;

    Insurance(String name) {
        this.name = name;
    }

    String getName() {
        return name;
    }
}

class Carr {
    String model;
    Optional<Insurance> insurance = Optional.empty();

    Carr(String model) {
        this.model = model;
    }

    void setInsurance(Insurance insurance) {
        this.insurance = Optional.ofNullable(insurance);
    }

    Optional<Insurance> getInsurance() {
        return insurance;
    }
}

class Person {
    String name;
    Optional<Carr> car = Optional.empty();

    Person(String name) {
        this.name = name;
    }

    void setCar(Carr car) {
        this.car = Optional.ofNullable(car);
    }

    Optional<Carr> getCar() {
        return car;
    }
}

public class Optional_Type_Example {
    public static void main(String[] args) {

        // scenario-1: person has car with insurance
        Insurance insurance1 = new Insurance("ABC Insurance");
        Carr car1 = new Carr("Toyota");
        car1.setInsurance(insurance1);
        Person person1 = new Person("John");
        person1.setCar(car1);

        // get person1's car's insurance name

        person1.getCar()
                .flatMap(Carr::getInsurance)
                .map(Insurance::getName)
                .ifPresentOrElse(
                        name -> System.out.println("Person1's car insurance name: " + name),
                        () -> System.out.println("Person1's car insurance name not available")
                );




        //------------------------------
        // get person2's car's insurance name
        //------------------------------

        // scenario-2: person has no car
        Person person2 = new Person("Alice");

        person2.getCar()
                .flatMap(Carr::getInsurance)
                .map(Insurance::getName)
                .ifPresentOrElse(
                        name -> System.out.println("Person2's car insurance name: " + name),
                        () -> System.out.println("Person2's car insurance name not available")
                );




    }
}
