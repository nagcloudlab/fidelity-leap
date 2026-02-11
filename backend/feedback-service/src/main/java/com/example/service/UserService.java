package com.example.service;

import com.example.dto.CreateUserRequestDto;
import com.example.dto.CreateUserResponseDto;
import com.example.entity.User;
import com.example.repository.UserRepository;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService implements UserDetailsService {

    private UserRepository userRepository;
    private PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }


    public CreateUserResponseDto createUser(CreateUserRequestDto createUserRequestDto) {
        // - input is valid
        // - check is username already exists
        // - save the user to the database
        // dto to entity
        User user = new User();
        user.setUsername(createUserRequestDto.getUsername());
        // - hash the password
        user.setPassword(passwordEncoder.encode(createUserRequestDto.getPassword()));
        user.setEmail(createUserRequestDto.getEmail());
        // - save the user to the database
        userRepository.save(user);
        // - return a response
        CreateUserResponseDto createUserResponseDto = new CreateUserResponseDto();
        createUserResponseDto.setUsername(user.getUsername());
        createUserResponseDto.setEmail(user.getEmail());
        createUserResponseDto.setMessage("User created successfully");
        return createUserResponseDto;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
        return org.springframework.security.core.userdetails.User
                .withUsername(user.getUsername())
                .password(user.getPassword())
                .authorities("USER") // You can set roles/authorities as needed
                .build();
    }
}
