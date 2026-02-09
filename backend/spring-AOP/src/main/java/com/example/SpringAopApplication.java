package com.example;

import com.example.service.TransferService;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

@SpringBootApplication
@EnableAspectJAutoProxy
public class SpringAopApplication {

    public static void main(String[] args) {

        // Init..
        ConfigurableApplicationContext context =
                SpringApplication.run(SpringAopApplication.class, args);

        // Use
        TransferService transferService = context.getBean(TransferService.class);
        System.out.println(transferService.getClass());
        transferService.transfer();

        // Close
        context.close();
    }

}
