package com.shopsphere.user.config;

import java.util.List;

import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import com.shopsphere.user.model.User;
import com.shopsphere.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@RequiredArgsConstructor
public class DataInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (!userRepository.existsByUsername("admin")) {
            log.info("Creating default admin user...");
            User admin = new User();
            admin.setUsername("admin");
            admin.setEmail("admin@shopsphere.com");
            admin.setPassword(passwordEncoder.encode("Admin@123"));
            admin.setFirstName("System");
            admin.setLastName("Admin");
            admin.setPhoneNumber("+12345678901");
            admin.setRoles(List.of("ROLE_USER", "ROLE_ADMIN"));
            admin.setEnabled(true);
            admin.setAccountNonExpired(true);
            admin.setAccountNonLocked(true);
            admin.setCredentialsNonExpired(true);
            userRepository.save(admin);
            log.info("Default admin user created successfully (username: admin)");
        }
    }
}
