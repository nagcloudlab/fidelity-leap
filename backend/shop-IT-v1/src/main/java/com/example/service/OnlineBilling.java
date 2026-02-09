package com.example.service;

import com.example.repository.PriceMatrixRepository;
import com.example.repository.PriceMatrixRepositoryFactory;
import org.slf4j.Logger;

import java.util.List;

/*

    --------------------------------------------------------------
    design issues
    --------------------------------------------------------------
    -> dependent & dependency components tightly coupled

        problems caused by tight coupling:
        ---------------------------------
        -> can't extend component with new features without modifying existing code
        -> unit-testing is difficult because of tight coupling
        -> dev & bug-fixing cycles are longer

    --------------------------------------------------------------
    performance issues
    --------------------------------------------------------------
    -> on each call to getTotalPrice, a new ExcelPriceMatrixRepository instance is created

        problems caused by this:
        ---------------------------------
        -> performance overhead of creating new instances repeatedly
        -> increased memory usage due to multiple instances
        -> potential resource leaks if instances are not properly managed
        -> user experience degradation due to slower response times

    --------------------------------------------------------------
    why these issues happen?
    --------------------------------------------------------------

    -> dependent manages the lifecycle of its dependencies directly

    solution:
    ---------------------------------
    -> don't create dependency in dependent's home, use Factory..

    is problem solved?
    ---------------------------------
    -> yes, dependent is no longer tightly coupled to a specific implementation of its dependency
    but still performance issue remains..

    best solution:
    ---------------------------------
    -> Don't create & Don't lookup dependency from dependent's home,
       inject by third party ( Inversion of Control - IoC / Dependency Injection - DI )

       how to achieve IoC/DI?
       ---------------------

       -> constructor Injection ( for required dependencies )
       -> setter Injection ( for optional dependencies )


       -------------------------------------------------
       Object design Principles aka SOLID principles
       -------------------------------------------------

         S - Single Responsibility Principle
         O - Open for extension/Closed for modification Principle
         L - Liskov Substitution Principle
         I - Interface Segregation Principle
         D - Dependency Inversion Principle  <== related to IoC/DI

       ----------------------------------------------



 */

public class OnlineBilling {

    private static Logger logger = org.slf4j.LoggerFactory.getLogger("shop-IT");

    private PriceMatrixRepository priceMatrixRepository ;

    public OnlineBilling(PriceMatrixRepository priceMatrixRepository) {
        this.priceMatrixRepository = priceMatrixRepository;
        logger.info("OnlineBilling component initialized.");
    }

    public double getTotalPrice(List<String> cart) {
        logger.info("Calculating total price for cart: " + cart);
//        ExcelPriceMatrixRepository priceMatrixRepository=new ExcelPriceMatrixRepository(); // Don't create
//         PriceMatrixRepository priceMatrixRepository= PriceMatrixRepositoryFactory.getPriceMatrixRepository("DB"); // Use Factory
        double totalPrice = 0.0;
        for (String itemCode : cart) {
            double price = priceMatrixRepository.getPrice(itemCode);
            totalPrice += price;
        }
        logger.info("Total price calculated: " + totalPrice);
        return totalPrice;
    }
}
