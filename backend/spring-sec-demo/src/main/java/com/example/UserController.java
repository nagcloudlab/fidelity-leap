package com.example;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class UserController {


    @GetMapping("/login")
    public String loginPage() {
        return "login-page";
    }

    @GetMapping("/access-denied")
    public String denied() {
        return "access-denied";
    }

}
