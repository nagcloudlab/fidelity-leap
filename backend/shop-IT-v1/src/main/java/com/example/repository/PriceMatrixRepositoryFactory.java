package com.example.repository;

public class PriceMatrixRepositoryFactory {

   public static PriceMatrixRepository getPriceMatrixRepository(String type) {
        switch (type) {
            case "Excel":
                return new ExcelPriceMatrixRepository();
            case "DB":
                return new DatabasePriceMatrixRepository();
            default:
                throw new IllegalArgumentException("Unknown repository type: " + type);
        }
    }

}
