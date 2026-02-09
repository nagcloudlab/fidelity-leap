package com.example.component;

import com.example.framework.RequestMapping;

public class UserController {

    @RequestMapping(url = "/login")
    public void doLogin(){
        System.out.println("User logged in");
    }

    @RequestMapping(url = "/registration")
    public void doRegister(){
        System.out.println("User registered");
    }

}
