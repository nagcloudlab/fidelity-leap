package com.example.service;

import com.example.repository.FooRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class TransferService {

    @Value("${fidelity.transfer.limit:10000.0}")
    double transferLimit;

    @Value("${fidelity.city:Unknown}")
    String city;

    @Autowired
    private FooRepository fooRepository;

    public void transfer() {
        System.out.println("TransferService: transfer executed");
        System.out.println("with limit: " + transferLimit);
        System.out.println("in city: " + city);
    }

}
