package com.doggo.controller;

import com.doggo.dto.PlaceDto;
import com.doggo.entity.ReviewStatus;
import com.doggo.service.PlaceService;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/admin/reviews")
public class AdminReviewController {

	private final PlaceService placeService;

	@GetMapping
	public List<PlaceDto.ReviewResponse> listReviews(
		@RequestParam(defaultValue = "UNDER_MODERATION") ReviewStatus status
	) {
		return placeService.listReviewsByStatus(status);
	}

	@PutMapping("/{reviewId}/publish")
	public PlaceDto.ReviewResponse publishReview(@PathVariable UUID reviewId) {
		return placeService.publishReview(reviewId);
	}

	@PutMapping("/{reviewId}/reject")
	public PlaceDto.ReviewResponse rejectReview(@PathVariable UUID reviewId) {
		return placeService.rejectReview(reviewId);
	}
}
