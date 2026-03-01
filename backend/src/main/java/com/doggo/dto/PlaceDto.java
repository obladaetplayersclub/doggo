package com.doggo.dto;

import com.doggo.entity.PlaceCategory;
import com.doggo.entity.ReviewStatus;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public final class PlaceDto {

	private PlaceDto() {
	}

	public record PlaceSummaryResponse(
		UUID id,
		String name,
		String address,
		String description,
		PlaceCategory category,
		String district,
		String metroStation,
		double latitude,
		double longitude,
		Double distanceMeters,
		double averageRating,
		long reviewCount
	) {
	}

	public record PlaceDetailsResponse(
		UUID id,
		String name,
		String address,
		String description,
		PlaceCategory category,
		String district,
		String metroStation,
		double latitude,
		double longitude,
		double averageRating,
		long reviewCount,
		List<ReviewResponse> reviews
	) {
	}

	public record ReviewUpsertRequest(
		@Min(1) @Max(5) int rating,
		@NotBlank @Size(max = 1000) String text
	) {
	}

	public record ReviewComplaintRequest(
		@NotBlank @Size(max = 500) String reason
	) {
	}

	public record ReviewResponse(
		UUID id,
		UUID authorId,
		String authorDisplayName,
		int rating,
		String text,
		ReviewStatus status,
		int complaintCount,
		OffsetDateTime createdAt,
		OffsetDateTime updatedAt
	) {
	}
}
