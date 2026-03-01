package com.doggo.service;

import com.doggo.dto.AuthDto;
import com.doggo.entity.UserAccount;
import com.doggo.exception.ApiException;
import com.doggo.repository.UserAccountRepository;
import com.doggo.security.AuthenticatedUser;
import com.doggo.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

	private final UserAccountRepository userAccountRepository;
	private final PasswordEncoder passwordEncoder;
	private final AuthenticationManager authenticationManager;
	private final JwtService jwtService;

	@Transactional
	public AuthDto.AuthResponse register(AuthDto.RegisterRequest request) {
		String email = normalizeEmail(request.email());
		if (userAccountRepository.existsByEmailIgnoreCase(email)) {
			throw new ApiException(HttpStatus.CONFLICT, "A user with this email already exists");
		}

		UserAccount user = new UserAccount();
		user.setEmail(email);
		user.setPasswordHash(passwordEncoder.encode(request.password()));
		user.setDisplayName(request.displayName().trim());
		user = userAccountRepository.save(user);

		AuthenticatedUser principal = AuthenticatedUser.from(user);
		return new AuthDto.AuthResponse(jwtService.generateToken(principal), toSummary(user));
	}

	public AuthDto.AuthResponse login(AuthDto.LoginRequest request) {
		String email = normalizeEmail(request.email());
		authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(email, request.password()));

		UserAccount user = userAccountRepository.findByEmailIgnoreCase(email)
			.orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));
		return new AuthDto.AuthResponse(jwtService.generateToken(AuthenticatedUser.from(user)), toSummary(user));
	}

	public AuthDto.UserSummary getCurrentUser(AuthenticatedUser user) {
		UserAccount account = userAccountRepository.findById(user.id())
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
		return toSummary(account);
	}

	private AuthDto.UserSummary toSummary(UserAccount user) {
		return new AuthDto.UserSummary(user.getId(), user.getEmail(), user.getDisplayName(), user.getAvatarUrl());
	}

	private String normalizeEmail(String email) {
		return email.trim().toLowerCase();
	}
}
