package com.example.repository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import javax.sql.DataSource;

@Repository
public class FooRepository {
    //..
    @Autowired
    private DataSource dataSource;

}
