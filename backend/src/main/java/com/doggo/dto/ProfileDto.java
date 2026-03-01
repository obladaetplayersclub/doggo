package com.doggo.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public final class ProfileDto {

	private ProfileDto() {
	}

	public record UpdateProfileRequest(
		@NotBlank @Size(min = 2, max = 120) String displayName,
		@Size(max = 512) String avatarUrl
	) {
	}

	public record ProfileResponse(
		UUID id,
		String email,
		String displayName,
		String avatarUrl,
		int petCount
	) {
	}
}
