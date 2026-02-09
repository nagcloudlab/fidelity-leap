package com.example;

/*

    design issues
    -------------

    1. code tangling: logging, authorization, and exception handling code are mixed with business logic.
    2. code scattering: logging, authorization, and exception handling code are duplicated across multiple
       business methods and components.

   solution: - design-pattern : proxy  pattern

 */

class TransferService {
    public void transfer() {
        System.out.println("TransferService: Transfer operation completed successfully.");
    }
}


class Logger {
    public void log(String message) {
        System.out.println("LOG: " + message);
    }
}

class Auth {
    public boolean checkAccess(String userRole) {
        // Simulate access check
        return "ADMIN".equals(userRole);
    }
}

class TransferServiceProxy {
    Logger logger = new Logger();
    Auth auth = new Auth();
    TransferService transferService = new TransferService();

    public void transfer() {
        logger.log("Starting transfer operation.");
        if (!auth.checkAccess("ADMIN")) {
            logger.log("Access denied for transfer operation.");
            return;
        }
        try {
            transferService.transfer();
        } catch (Exception e) {
            logger.log("Exception during transfer: " + e.getMessage());
        }
    }
}

public class Example {
    public static void main(String[] args) {

        TransferServiceProxy transferService = new TransferServiceProxy();
        transferService.transfer();

    }
}
