package com.example;

import com.example.framework.WebFramework;

public class WebApplication {
    public static void main(String[] args) {
        WebFramework webFramework=new WebFramework();
        webFramework.handleHttpRequest("/login");

    }
}
