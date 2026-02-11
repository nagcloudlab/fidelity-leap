package com.example.security;

import com.example.dto.CreateUserRequestDto;
import com.example.dto.CreateUserResponseDto;
import com.example.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class UserAuthController {

    public UserService userService;
    private AuthenticationManager authManager;
    private JwtUtil jwtUtil;
    private PasswordEncoder passwordEncoder;

    public UserAuthController(UserService userService, AuthenticationManager authManager, JwtUtil jwtUtil, PasswordEncoder passwordEncoder) {
        this.userService = userService;
        this.authManager = authManager;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping(
            value = "/register",
            consumes = {"application/json"},
            produces = {"application/json"}
    )
    public ResponseEntity<?> createUser(@RequestBody CreateUserRequestDto createUserRequestDto) {
        CreateUserResponseDto createUserResponseDto= userService.createUser(createUserRequestDto);
        // 201
        return ResponseEntity.status(201).body(createUserResponseDto);
    }

    @PostMapping("/login")
    public AuthResponse login(@RequestBody AuthRequest request) {
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getUsername(),
                        request.getPassword()
                )
        );
        String token = jwtUtil.generateToken(request.getUsername());
        return new AuthResponse(token);
    }

}
