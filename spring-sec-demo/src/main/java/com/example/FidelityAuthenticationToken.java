package com.example;

import lombok.Getter;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;

@Getter
public class FidelityAuthenticationToken extends UsernamePasswordAuthenticationToken {
    private final String domain;
    public FidelityAuthenticationToken(String username, String password, String domain) {
        super(username, password);
        this.domain = domain;
    }
    public FidelityAuthenticationToken(String username, String password, String domain,
                                  Collection<? extends GrantedAuthority> authorities) {
        super(username, password, authorities);
        this.domain = domain;
    }
}
