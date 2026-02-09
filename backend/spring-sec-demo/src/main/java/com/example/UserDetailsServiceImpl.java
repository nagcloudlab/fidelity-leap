package com.example;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {


    @Autowired
    InMemoryUserStore userStore;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {

        FidelityUser fidelityUser= userStore.find(username).orElseThrow(()-> new UsernameNotFoundException("User not found: "+username));

        List<String> roles= fidelityUser.getRoles();
        List<GrantedAuthority> authorities= roles.stream()
                .map(role-> (GrantedAuthority) ()-> role)
                .toList();

        UserDetails userDetails= new User(
                fidelityUser.getUsername(),
                fidelityUser.getPassword(),
                authorities
        );
        return userDetails;

    }
}
