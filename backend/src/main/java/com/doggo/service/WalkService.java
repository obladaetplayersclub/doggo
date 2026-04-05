package com.doggo.service;

import com.doggo.dto.WalkDto;
import com.doggo.entity.Pet;
import com.doggo.entity.Walk;
import com.doggo.entity.WalkPoint;
import com.doggo.entity.WalkStatus;
import com.doggo.exception.ApiException;
import com.doggo.repository.UserAccountRepository;
import com.doggo.repository.WalkPointRepository;
import com.doggo.repository.WalkRepository;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WalkService {

	private final WalkRepository walkRepository;
	private final WalkPointRepository pointRepository;
	private final UserAccountRepository userAccountRepository;
	private final PetService petService;

	public List<WalkDto.WalkResponse> list(UUID ownerId, UUID petId) {
		petService.getOwnedPet(ownerId, petId);
		return walkRepository.findAllByOwnerIdAndPetIdOrderByStartedAtDesc(ownerId, petId).stream()
			.map(this::toResponse)
			.toList();
	}

	@Transactional
	public WalkDto.WalkResponse start(UUID ownerId, UUID petId, WalkDto.StartWalkRequest request) {
		Pet pet = petService.getOwnedPet(ownerId, petId);
		if (walkRepository.findByPetIdAndStatus(petId, WalkStatus.ACTIVE).isPresent()) {
			throw new ApiException(HttpStatus.CONFLICT, "Pet already has an active walk");
		}
		Walk walk = new Walk();
		walk.setOwner(userAccountRepository.findById(ownerId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found")));
		walk.setPet(pet);
		walk.setStartedAt(request.startedAt() == null ? OffsetDateTime.now() : request.startedAt());
		walk.setStatus(WalkStatus.ACTIVE);
		return toResponse(walkRepository.save(walk));
	}

	@Transactional
	public WalkDto.WalkResponse addPoints(UUID ownerId, UUID walkId, WalkDto.AddWalkPointsRequest request) {
		Walk walk = getOwnedWalk(ownerId, walkId);
		if (walk.getStatus() != WalkStatus.ACTIVE) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Walk is already finished");
		}

		List<WalkPoint> existingPoints = pointRepository.findAllByWalkIdOrderByRecordedAtAsc(walkId);
		WalkPoint previous = existingPoints.isEmpty() ? null : existingPoints.get(existingPoints.size() - 1);
		double additionalDistance = 0;
		for (WalkDto.WalkPointRequest pointRequest : request.points()) {
			WalkPoint point = new WalkPoint();
			point.setWalk(walk);
			point.setLatitude(pointRequest.latitude());
			point.setLongitude(pointRequest.longitude());
			point.setRecordedAt(pointRequest.recordedAt());
			if (previous != null) {
				additionalDistance += PlaceService.haversineMeters(
					previous.getLatitude(),
					previous.getLongitude(),
					point.getLatitude(),
					point.getLongitude()
				);
			}
			previous = pointRepository.save(point);
		}
		walk.setDistanceMeters(walk.getDistanceMeters() + additionalDistance);
		return toResponse(walk);
	}

	@Transactional
	public WalkDto.WalkResponse finish(UUID ownerId, UUID walkId, WalkDto.FinishWalkRequest request) {
		Walk walk = getOwnedWalk(ownerId, walkId);
		if (walk.getStatus() == WalkStatus.FINISHED) {
			return toResponse(walk);
		}
		OffsetDateTime endedAt = request.endedAt() == null ? OffsetDateTime.now() : request.endedAt();
		if (endedAt.isBefore(walk.getStartedAt())) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Walk end time cannot be before start time");
		}
		walk.setEndedAt(endedAt);
		walk.setStatus(WalkStatus.FINISHED);
		return toResponse(walk);
	}

	public WalkDto.WalkStatsResponse stats(UUID ownerId, UUID petId) {
		petService.getOwnedPet(ownerId, petId);
		List<Walk> walks = walkRepository.findAllByOwnerIdAndPetIdOrderByStartedAtDesc(ownerId, petId);
		double totalDistance = walks.stream().mapToDouble(Walk::getDistanceMeters).sum();
		long totalDuration = walks.stream().mapToLong(this::durationSeconds).sum();
		return new WalkDto.WalkStatsResponse(petId, walks.size(), totalDistance, totalDuration);
	}

	private Walk getOwnedWalk(UUID ownerId, UUID walkId) {
		return walkRepository.findByIdAndOwnerId(walkId, ownerId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Walk not found"));
	}

	private WalkDto.WalkResponse toResponse(Walk walk) {
		return new WalkDto.WalkResponse(
			walk.getId(),
			walk.getPet().getId(),
			walk.getPet().getName(),
			walk.getStartedAt(),
			walk.getEndedAt(),
			walk.getDistanceMeters(),
			durationSeconds(walk),
			walk.getStatus()
		);
	}

	private long durationSeconds(Walk walk) {
		OffsetDateTime end = walk.getEndedAt() == null ? OffsetDateTime.now() : walk.getEndedAt();
		return Math.max(0, Duration.between(walk.getStartedAt(), end).toSeconds());
	}
}
