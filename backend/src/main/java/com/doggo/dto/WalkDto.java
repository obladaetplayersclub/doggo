package com.doggo.dto;

import com.doggo.entity.WalkStatus;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public final class WalkDto {

	private WalkDto() {
	}

	public record StartWalkRequest(OffsetDateTime startedAt) {
	}

	public record FinishWalkRequest(OffsetDateTime endedAt) {
	}

	public record WalkPointRequest(
		@NotNull Double latitude,
		@NotNull Double longitude,
		@NotNull OffsetDateTime recordedAt
	) {
	}

	public record AddWalkPointsRequest(
		@NotEmpty List<WalkPointRequest> points
	) {
	}

	public record WalkResponse(
		UUID id,
		UUID petId,
		String petName,
		OffsetDateTime startedAt,
		OffsetDateTime endedAt,
		double distanceMeters,
		long durationSeconds,
		WalkStatus status
	) {
	}

	public record WalkStatsResponse(
		UUID petId,
		long totalWalks,
		double totalDistanceMeters,
		long totalDurationSeconds
	) {
	}
}
