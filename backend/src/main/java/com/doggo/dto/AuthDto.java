package com.doggo.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public final class AuthDto {

	private AuthDto() {
	}

	public record RegisterRequest(
		@NotBlank @Email String email,
		@NotBlank @Size(min = 8, max = 72) String password,
		@NotBlank @Size(min = 2, max = 120) String displayName
	) {
	}

	public record LoginRequest(
		@NotBlank @Email String email,
		@NotBlank String password
	) {
	}

	public record AuthResponse(
		String token,
		UserSummary user
	) {
	}

	public record UserSummary(
		UUID id,
		String email,
		String displayName,
		String avatarUrl
	) {
	}
}
