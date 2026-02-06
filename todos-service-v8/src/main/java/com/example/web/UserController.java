package com.example.web;

import com.example.dto.CreateUserDto;
import com.example.entity.Role;
import com.example.entity.User;
import com.example.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.util.List;
import java.util.Optional;

@Controller
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @GetMapping("/register")
    public String showRegistrationForm() {
        return "register-form";
    }

    @PostMapping("/register")
    public String processRegistration(@ModelAttribute CreateUserDto createUserDto) {
        User user = new User();
        user.setUsername(createUserDto.getUsername());
        user.setEmail(createUserDto.getEmail());
        user.setPassword(passwordEncoder.encode(createUserDto.getPassword()));
        List<Role> roles = List.of(
                new Role(3)
        );
        user.setRoles(roles);
        userRepository.save(user);
        return "redirect:/login";
    }


    @GetMapping("/login")
    public String showLoginForm(@RequestParam("error") Optional<String> error, Model model) {
        if (error.isPresent()) {
            System.out.println("Login error occurred");
            System.out.println(error.get());
            model.addAttribute("loginError", true);
        }
        return "login-form";
    }

}
