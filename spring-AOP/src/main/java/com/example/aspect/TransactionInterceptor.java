package com.example.aspect;

import org.aspectj.lang.annotation.AfterReturning;
import org.aspectj.lang.annotation.AfterThrowing;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.springframework.stereotype.Component;

@Component
@Aspect
public class TransactionInterceptor {

    TransactionManager transactionManager=new TransactionManager();


    @Before(("execution(* com.example.service.*.*(..))") )
    public void beginTransaction() {
        transactionManager.begin();
    }

    @AfterReturning("execution(* com.example.service.*.*(..))")
    public void commitTransaction() {
        transactionManager.commit();
    }

    @AfterThrowing("execution(* com.example.service.*.*(..))")
    public void rollbackTransaction() {
        transactionManager.rollback();
    }

}
