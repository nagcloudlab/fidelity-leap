package com.example.repository;

import org.slf4j.Logger;

/**
 * author: team-1
 */

public class ExcelPriceMatrixRepository implements PriceMatrixRepository {

    private static Logger logger = org.slf4j.LoggerFactory.getLogger("shop-IT");

    public ExcelPriceMatrixRepository(){
        logger.info("ExcelPriceMatrixRepository component initialized.");
    }

    public double getPrice(String itemCode) {
        logger.info("Fetching price for item code: " + itemCode);
        // Implementation to get price from Excel file
        return 1000.00;
    }

}
