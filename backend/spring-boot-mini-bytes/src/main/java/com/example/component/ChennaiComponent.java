package com.example.component;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.condition.ConditionalOnWebApplication;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "fidelity.city", havingValue = "chennai")
public class ChennaiComponent {

    public String getCityName() {
        return "Chennai";
    }

}
