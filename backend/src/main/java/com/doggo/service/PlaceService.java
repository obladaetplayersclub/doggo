package com.doggo.service;

import com.doggo.config.ReviewProperties;
import com.doggo.dto.PlaceDto;
import com.doggo.entity.Place;
import com.doggo.entity.PlaceCategory;
import com.doggo.entity.Review;
import com.doggo.entity.ReviewComplaint;
import com.doggo.entity.ReviewStatus;
import com.doggo.entity.UserAccount;
import com.doggo.exception.ApiException;
import com.doggo.repository.PlaceRepository;
import com.doggo.repository.ReviewComplaintRepository;
import com.doggo.repository.ReviewRatingProjection;
import com.doggo.repository.ReviewRepository;
import com.doggo.repository.UserAccountRepository;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class PlaceService {

	private final PlaceRepository placeRepository;
	private final ReviewRepository reviewRepository;
	private final ReviewComplaintRepository complaintRepository;
	private final UserAccountRepository userAccountRepository;
	private final ReviewProperties reviewProperties;

	public List<PlaceDto.PlaceSummaryResponse> search(
		String query,
		PlaceCategory category,
		String district,
		String metro,
		Double latitude,
		Double longitude,
		Double radiusKm,
		String sort
	) {
		List<Place> places = placeRepository.findAll().stream()
			.filter(place -> matchesText(place, query))
			.filter(place -> category == null || place.getCategory() == category)
			.filter(place -> matchesIgnoreCase(place.getDistrict(), district))
			.filter(place -> matchesIgnoreCase(place.getMetroStation(), metro))
			.toList();

		Map<UUID, RatingSummary> ratings = ratingSummaries(places);
		List<PlaceDto.PlaceSummaryResponse> responses = places.stream()
			.map(place -> toSummary(place, ratings.getOrDefault(place.getId(), RatingSummary.empty()), latitude, longitude))
			.filter(place -> radiusKm == null || place.distanceMeters() != null && place.distanceMeters() <= radiusKm * 1000)
			.toList();

		Comparator<PlaceDto.PlaceSummaryResponse> comparator = "rating".equalsIgnoreCase(sort)
			? Comparator.comparingDouble(PlaceDto.PlaceSummaryResponse::averageRating).reversed()
			: Comparator.comparing(response -> response.distanceMeters() == null ? Double.MAX_VALUE : response.distanceMeters());
		return responses.stream().sorted(comparator).toList();
	}

	public PlaceDto.PlaceDetailsResponse getPlace(UUID placeId) {
		Place place = getPlaceEntity(placeId);
		RatingSummary rating = ratingSummary(placeId);
		List<PlaceDto.ReviewResponse> reviews = reviewRepository
			.findAllByPlaceIdAndStatusOrderByCreatedAtDesc(placeId, ReviewStatus.PUBLISHED)
			.stream()
			.map(this::toReviewResponse)
			.toList();
		return new PlaceDto.PlaceDetailsResponse(
			place.getId(),
			place.getName(),
			place.getAddress(),
			place.getDescription(),
			place.getCategory(),
			place.getDistrict(),
			place.getMetroStation(),
			place.getLatitude(),
			place.getLongitude(),
			rating.averageRating(),
			rating.reviewCount(),
			reviews
		);
	}

	@Transactional
	public PlaceDto.ReviewResponse upsertReview(UUID userId, UUID placeId, PlaceDto.ReviewUpsertRequest request) {
		validateReviewText(request.text());
		UserAccount author = userAccountRepository.findById(userId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
		Place place = getPlaceEntity(placeId);

		Review review = reviewRepository.findByPlaceIdAndAuthorId(placeId, userId).orElseGet(() -> {
			checkDailyReviewLimit(userId);
			Review created = new Review();
			created.setAuthor(author);
			created.setPlace(place);
			return created;
		});
		review.setRating(request.rating());
		review.setText(request.text().trim());
		review.setStatus(ReviewStatus.PUBLISHED);
		return toReviewResponse(reviewRepository.save(review));
	}

	public List<PlaceDto.ReviewResponse> listReviews(UUID placeId) {
		getPlaceEntity(placeId);
		return reviewRepository.findAllByPlaceIdAndStatusOrderByCreatedAtDesc(placeId, ReviewStatus.PUBLISHED).stream()
			.map(this::toReviewResponse)
			.toList();
	}

	@Transactional
	public void deleteOwnReview(UUID userId, UUID placeId) {
		Review review = reviewRepository.findByPlaceIdAndAuthorId(placeId, userId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Review not found"));
		reviewRepository.delete(review);
	}

	@Transactional
	public PlaceDto.ReviewResponse complain(UUID userId, UUID placeId, UUID reviewId, PlaceDto.ReviewComplaintRequest request) {
		Review review = reviewRepository.findByIdAndPlaceId(reviewId, placeId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Review not found"));
		UserAccount reporter = userAccountRepository.findById(userId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
		if (review.getAuthor().getId().equals(userId)) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "You cannot complain about your own review");
		}
		if (complaintRepository.existsByReviewIdAndReporterId(reviewId, userId)) {
			throw new ApiException(HttpStatus.CONFLICT, "Complaint already exists");
		}

		ReviewComplaint complaint = new ReviewComplaint();
		complaint.setReview(review);
		complaint.setReporter(reporter);
		complaint.setReason(request.reason().trim());
		complaintRepository.save(complaint);

		review.setComplaintCount(review.getComplaintCount() + 1);
		if (review.getComplaintCount() >= 3) {
			review.setStatus(ReviewStatus.UNDER_MODERATION);
		}
		return toReviewResponse(review);
	}

	private Place getPlaceEntity(UUID placeId) {
		return placeRepository.findById(placeId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found"));
	}

	private void validateReviewText(String text) {
		int length = text == null ? 0 : text.trim().length();
		if (length < reviewProperties.minLength() || length > reviewProperties.maxLength()) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Review length is outside configured limits");
		}
	}

	private void checkDailyReviewLimit(UUID userId) {
		OffsetDateTime start = LocalDate.now(ZoneOffset.UTC).atStartOfDay().atOffset(ZoneOffset.UTC);
		OffsetDateTime end = start.plusDays(1);
		long count = reviewRepository.countByAuthorIdAndCreatedAtBetween(userId, start, end);
		if (count >= reviewProperties.dailyLimit()) {
			throw new ApiException(HttpStatus.TOO_MANY_REQUESTS, "Daily review limit exceeded");
		}
	}

	private boolean matchesText(Place place, String query) {
		if (query == null || query.isBlank()) {
			return true;
		}
		String normalized = query.trim().toLowerCase();
		return place.getName().toLowerCase().contains(normalized)
			|| place.getAddress().toLowerCase().contains(normalized);
	}

	private boolean matchesIgnoreCase(String actual, String expected) {
		return expected == null || expected.isBlank() || actual != null && actual.equalsIgnoreCase(expected.trim());
	}

	private Map<UUID, RatingSummary> ratingSummaries(List<Place> places) {
		if (places.isEmpty()) {
			return Map.of();
		}
		List<UUID> placeIds = places.stream().map(Place::getId).toList();
		Map<UUID, RatingSummary> result = new HashMap<>();
		for (ReviewRatingProjection projection : reviewRepository.summarizePublishedRatings(placeIds, ReviewStatus.PUBLISHED)) {
			result.put(projection.getPlaceId(), new RatingSummary(
				projection.getAverageRating() == null ? 0 : projection.getAverageRating(),
				projection.getReviewCount()
			));
		}
		return result;
	}

	private RatingSummary ratingSummary(UUID placeId) {
		long count = reviewRepository.countByPlaceIdAndStatus(placeId, ReviewStatus.PUBLISHED);
		if (count == 0) {
			return RatingSummary.empty();
		}
		Map<UUID, RatingSummary> summaries = ratingSummaries(List.of(getPlaceEntity(placeId)));
		return summaries.getOrDefault(placeId, RatingSummary.empty());
	}

	private PlaceDto.PlaceSummaryResponse toSummary(Place place, RatingSummary rating, Double latitude, Double longitude) {
		return new PlaceDto.PlaceSummaryResponse(
			place.getId(),
			place.getName(),
			place.getAddress(),
			place.getDescription(),
			place.getCategory(),
			place.getDistrict(),
			place.getMetroStation(),
			place.getLatitude(),
			place.getLongitude(),
			distance(latitude, longitude, place.getLatitude(), place.getLongitude()),
			rating.averageRating(),
			rating.reviewCount()
		);
	}

	private PlaceDto.ReviewResponse toReviewResponse(Review review) {
		return new PlaceDto.ReviewResponse(
			review.getId(),
			review.getAuthor().getId(),
			review.getAuthor().getDisplayName(),
			review.getRating(),
			review.getText(),
			review.getStatus(),
			review.getComplaintCount(),
			review.getCreatedAt(),
			review.getUpdatedAt()
		);
	}

	private Double distance(Double fromLat, Double fromLon, double toLat, double toLon) {
		if (fromLat == null || fromLon == null) {
			return null;
		}
		return haversineMeters(fromLat, fromLon, toLat, toLon);
	}

	static double haversineMeters(double fromLat, double fromLon, double toLat, double toLon) {
		double earthRadiusMeters = 6_371_000;
		double lat1 = Math.toRadians(fromLat);
		double lat2 = Math.toRadians(toLat);
		double deltaLat = Math.toRadians(toLat - fromLat);
		double deltaLon = Math.toRadians(toLon - fromLon);
		double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
			+ Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);
		double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
		return earthRadiusMeters * c;
	}

	private record RatingSummary(double averageRating, long reviewCount) {

		static RatingSummary empty() {
			return new RatingSummary(0, 0);
		}
	}
}
