package com.example.service;

import com.example.dto.CreateUserDto;
import com.example.entity.User;

public interface UserService {

    void createUser(CreateUserDto createUserDto);
    User findUserByUsername(String username);


}
