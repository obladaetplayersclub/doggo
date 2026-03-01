package com.doggo.service;

import com.doggo.dto.ProfileDto;
import com.doggo.entity.UserAccount;
import com.doggo.exception.ApiException;
import com.doggo.repository.PetRepository;
import com.doggo.repository.UserAccountRepository;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProfileService {

	private final UserAccountRepository userAccountRepository;
	private final PetRepository petRepository;

	public ProfileDto.ProfileResponse getProfile(UUID userId) {
		UserAccount user = getUser(userId);
		return toResponse(user);
	}

	@Transactional
	public ProfileDto.ProfileResponse updateProfile(UUID userId, ProfileDto.UpdateProfileRequest request) {
		UserAccount user = getUser(userId);
		user.setDisplayName(request.displayName().trim());
		user.setAvatarUrl(blankToNull(request.avatarUrl()));
		return toResponse(user);
	}

	private UserAccount getUser(UUID userId) {
		return userAccountRepository.findById(userId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
	}

	private ProfileDto.ProfileResponse toResponse(UserAccount user) {
		return new ProfileDto.ProfileResponse(
			user.getId(),
			user.getEmail(),
			user.getDisplayName(),
			user.getAvatarUrl(),
			petRepository.findAllByOwnerIdOrderByCreatedAtDesc(user.getId()).size()
		);
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
