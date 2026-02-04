package com.example.aspect;

import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.aspectj.lang.annotation.Pointcut;
import org.springframework.stereotype.Component;

// aspect
@Aspect
@Component
public class LoggingAspect {
    // advice -> pointcut expression -> joinpoint
    @Before("execution(* com.example..*(..))")
    public  void logBeforeMethod(){
        System.out.println("LoggingAspect: Before method execution.");
    }
}
