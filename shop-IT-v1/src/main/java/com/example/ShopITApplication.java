package com.example;

import com.example.repository.PriceMatrixRepository;
import com.example.repository.PriceMatrixRepositoryFactory;
import com.example.service.OnlineBilling;
import org.slf4j.Logger;

import java.util.List;

public class ShopITApplication {

    private static Logger logger = org.slf4j.LoggerFactory.getLogger("shop-IT");

    public static void main(String[] args) {

        logger.info("Starting Shop-IT Application...");

        //---------------------------------
        // Init / boot phase
        //---------------------------------
        logger.info("-".repeat(50));
        // create components, set up dependencies, etc. based on configuration
        PriceMatrixRepository excelPriceMatrixRepository = PriceMatrixRepositoryFactory.getPriceMatrixRepository("Excel");
        PriceMatrixRepository dbPriceMatrixRepository = PriceMatrixRepositoryFactory.getPriceMatrixRepository("DB");
        OnlineBilling onlineBilling = new OnlineBilling(dbPriceMatrixRepository);

        logger.info("-".repeat(50));
        //---------------------------------
        // Run/Use phase
        //---------------------------------

        List<String> cart1 = List.of("itemA", "itemB", "itemC");
        double total1 = onlineBilling.getTotalPrice(cart1);
        System.out.println("Total price for cart1: " + total1);
        logger.info("-".repeat(25));
        List<String> cart2 = List.of("itemD", "itemE");
        ;
        double total2 = onlineBilling.getTotalPrice(cart2);
        System.out.println("Total price for cart2: " + total2);

        logger.info("-".repeat(50));
        //---------------------------------
        // Shutdown phase
        //---------------------------------
        logger.info("-".repeat(50));
        logger.info("-".repeat(50));

    }
}
