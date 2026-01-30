package com.example.day2;

/*

    2 types throwable
    - Exception => we can recover from it
        - Checked Exception => must be declared or handled
        - Unchecked Exception => RuntimeException and its subclasses
    - Error => we cannot recover from it

 */


class AccountNotFoundException extends RuntimeException {
    AccountNotFoundException(String message) {
        super(message);
    }
}

class InsufficientBalanceException extends RuntimeException {
    InsufficientBalanceException(String message) {
        super(message);
    }
}

// error
class StackOverflowError extends Error {
    StackOverflowError(String message) {
        super(message);
    }
}

//-----------------------------------------------------------
// Transfer Module from team-1
//-----------------------------------------------------------

class TransferService {
    void transfer(String fromAccount, String toAccount, double amount) {
        // load account details from DB
        // if account not exist..
        boolean isFromAccountExist = true;
        if (!isFromAccountExist) {
            throw new AccountNotFoundException("From account not found: " + fromAccount);
        }
        // check balance
        boolean hasSufficientBalance = false;
        if (!hasSufficientBalance) {
            throw new InsufficientBalanceException("Insufficient balance in account: " + fromAccount);
        }
    }
}


//-----------------------------------------------------------
// Ticket Booking Module from team-1
//-----------------------------------------------------------

class TicketBookingService {
    TransferService transferService = new TransferService(); // HAS-A

    void bookTicket(String passengerName, String from, String to) {
        // booking logic
        try {
            transferService.transfer("ACC-123", "ACC-456", 1000.0);
            System.out.println("Ticket booked successfully for " + passengerName);
        } catch (AccountNotFoundException ex) {
            // handling the exception
            // - displya friendly message to user
            // - log the error
            // - release connection externals resources
            // - excute plan-B ( fallback )
            // - re-throw the exception
            System.out.println("Failed to book ticket: " + ex.getMessage());
        } catch (InsufficientBalanceException ex) {
            System.out.println("Failed to book ticket: " + ex.getMessage());
        }
    }
}


public class Application {
    public static void main(String[] args) {

        TicketBookingService bookingService = new TicketBookingService();
        bookingService.bookTicket("John Doe", "NYC", "LA");

        String s = null;
        s.length();

    }
}
