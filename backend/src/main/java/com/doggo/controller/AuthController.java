package com.doggo.controller;

import com.doggo.dto.AuthDto;
import com.doggo.security.AuthenticatedUser;
import com.doggo.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/auth")
public class AuthController {

	private final AuthService authService;

	@PostMapping("/register")
	@ResponseStatus(HttpStatus.CREATED)
	public AuthDto.AuthResponse register(@Valid @RequestBody AuthDto.RegisterRequest request) {
		return authService.register(request);
	}

	@PostMapping("/login")
	public AuthDto.AuthResponse login(@Valid @RequestBody AuthDto.LoginRequest request) {
		return authService.login(request);
	}

	@GetMapping("/me")
	public AuthDto.UserSummary me(@AuthenticationPrincipal AuthenticatedUser user) {
		return authService.getCurrentUser(user);
	}
}
