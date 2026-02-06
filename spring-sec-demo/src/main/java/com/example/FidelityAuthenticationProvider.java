package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class FidelityAuthenticationProvider implements org.springframework.security.authentication.AuthenticationProvider {

    @Autowired
    private InMemoryUserStore userStore;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        FidelityAuthenticationToken token = (FidelityAuthenticationToken) authentication;

        FidelityUser user = userStore.find(token.getName())
                .orElseThrow(() -> new BadCredentialsException("User not found"));

        if (!passwordEncoder.matches(token.getCredentials().toString(), user.getPassword())
                || !user.getDomain().equals(token.getDomain())) {
            throw new BadCredentialsException("Invalid credentials or domain");
        }

        List<SimpleGrantedAuthority> authorities = user.getRoles().stream()
                .map(SimpleGrantedAuthority::new)
                .toList();

        return new FidelityAuthenticationToken(user.getUsername(), user.getPassword(), user.getDomain(), authorities);
    }


    @Override
    public boolean supports(Class<?> authentication) {
        return authentication.equals(FidelityAuthenticationToken.class);
    }
}
