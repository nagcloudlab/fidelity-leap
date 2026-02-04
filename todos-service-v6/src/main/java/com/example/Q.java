package com.example;

class TransferRequestDto{
    String fromUPI;
    String toUPI;
    double amount;

    TransferRequestDto(String fromUPI, String toUPI, double amount){
        this.fromUPI = fromUPI;
        this.toUPI = toUPI;
        this.amount = amount;
    }
}


class UPITransferService{
    void transfer(TransferRequestDto transferRequestDto){
        // Logic to perform UPI transfer
    }
}

public class Q {
    public static void main(String[] args) {



    }
}
