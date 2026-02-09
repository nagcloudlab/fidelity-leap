package com.example;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.security.Principal;
import java.util.List;

@Controller
@RequestMapping("/accounts")
public class AccountController {

    @GetMapping
    public String getAccountsPage(Model model, Principal principal) {
        Authentication authentication = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
        String username = authentication.getName();
        List<GrantedAuthority> authorities = (List<GrantedAuthority>) authentication.getAuthorities();

        System.out.println("-".repeat(50));
        System.out.println(username);
        authorities.forEach(authority -> System.out.println(authority.getAuthority()));
        System.out.println("-".repeat(50));

        List<Account> accounts = List.of(
                new Account("123456", "John Doe", "Savings", 1500.75),
                new Account("654321", "Jane Smith", "Checking", 2500.00),
                new Account("112233", "Alice Johnson", "Savings", 3200.50));
        model.addAttribute("accounts", accounts);
        return "accounts";
    }
}
