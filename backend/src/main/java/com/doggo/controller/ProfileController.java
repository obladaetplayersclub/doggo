package com.doggo.controller;

import com.doggo.dto.ProfileDto;
import com.doggo.security.AuthenticatedUser;
import com.doggo.service.ProfileService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/profile")
public class ProfileController {

	private final ProfileService profileService;

	@GetMapping
	public ProfileDto.ProfileResponse getProfile(@AuthenticationPrincipal AuthenticatedUser user) {
		return profileService.getProfile(user.id());
	}

	@PutMapping
	public ProfileDto.ProfileResponse updateProfile(
		@AuthenticationPrincipal AuthenticatedUser user,
		@Valid @RequestBody ProfileDto.UpdateProfileRequest request
	) {
		return profileService.updateProfile(user.id(), request);
	}
}
