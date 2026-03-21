package com.doggo.controller;

import com.doggo.dto.PlaceDto;
import com.doggo.entity.PlaceCategory;
import com.doggo.security.AuthenticatedUser;
import com.doggo.service.PlaceService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/places")
public class PlaceController {

	private final PlaceService placeService;

	@GetMapping
	public List<PlaceDto.PlaceSummaryResponse> search(
		@RequestParam(required = false) String query,
		@RequestParam(required = false) PlaceCategory category,
		@RequestParam(required = false) String district,
		@RequestParam(required = false) String metro,
		@RequestParam(required = false) Double latitude,
		@RequestParam(required = false) Double longitude,
		@RequestParam(required = false) Double radiusKm,
		@RequestParam(defaultValue = "distance") String sort
	) {
		return placeService.search(query, category, district, metro, latitude, longitude, radiusKm, sort);
	}

	@GetMapping("/{placeId}")
	public PlaceDto.PlaceDetailsResponse getPlace(@PathVariable UUID placeId) {
		return placeService.getPlace(placeId);
	}

	@GetMapping("/{placeId}/reviews")
	public List<PlaceDto.ReviewResponse> listReviews(@PathVariable UUID placeId) {
		return placeService.listReviews(placeId);
	}

	@PutMapping("/{placeId}/reviews/me")
	public PlaceDto.ReviewResponse upsertMyReview(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID placeId,
		@Valid @RequestBody PlaceDto.ReviewUpsertRequest request
	) {
		return placeService.upsertReview(user.id(), placeId, request);
	}

	@DeleteMapping("/{placeId}/reviews/me")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void deleteMyReview(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID placeId) {
		placeService.deleteOwnReview(user.id(), placeId);
	}

	@PostMapping("/{placeId}/reviews/{reviewId}/complaints")
	public PlaceDto.ReviewResponse complain(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID placeId,
		@PathVariable UUID reviewId,
		@Valid @RequestBody PlaceDto.ReviewComplaintRequest request
	) {
		return placeService.complain(user.id(), placeId, reviewId, request);
	}
}
