package com.example;

import com.example.component.ChennaiComponent;
import com.example.service.TransferService;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

@SpringBootApplication
public class SpringBootMiniBytesApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext context =
                SpringApplication.run(SpringBootMiniBytesApplication.class, args);

//        TransferService transferService= context.getBean(TransferService.class);
//        transferService.transfer();

        ChennaiComponent chennaiComponent = context.getBean(ChennaiComponent.class);
        System.out.println("City Name: " + chennaiComponent.getCityName());

    }

}
