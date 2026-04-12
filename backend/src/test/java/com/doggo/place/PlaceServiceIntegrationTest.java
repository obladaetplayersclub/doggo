package com.doggo.place;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.doggo.dto.PlaceDto;
import com.doggo.entity.Place;
import com.doggo.entity.PlaceCategory;
import com.doggo.entity.ReviewStatus;
import com.doggo.exception.ApiException;
import com.doggo.repository.PlaceRepository;
import com.doggo.service.PlaceService;
import com.doggo.support.IntegrationTestSupport;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class PlaceServiceIntegrationTest extends IntegrationTestSupport {

	@Autowired
	private PlaceService placeService;

	@Autowired
	private PlaceRepository placeRepository;

	@Test
	void placeReviewAffectsRatingAndCanBeReported() {
		UUID authorId = registerUser("review-author").user().id();
		UUID reporterId = registerUser("review-reporter").user().id();
		PlaceDto.PlaceSummaryResponse place = placeService.search(
			null,
			PlaceCategory.VET_CLINIC,
			null,
			null,
			null,
			null,
			null,
			"rating"
		).getFirst();
		PlaceDto.ReviewUpsertRequest reviewRequest = new PlaceDto.ReviewUpsertRequest(
			5,
			"Very careful doctors and clear recommendations."
		);

		PlaceDto.ReviewResponse pendingReview = placeService.upsertReview(authorId, place.id(), reviewRequest);
		assertThat(pendingReview.status()).isEqualTo(ReviewStatus.UNDER_MODERATION);
		assertThat(placeService.getPlace(place.id()).reviews()).isEmpty();

		PlaceDto.ReviewResponse review = placeService.publishReview(pendingReview.id());
		PlaceDto.PlaceDetailsResponse details = placeService.getPlace(place.id());
		PlaceDto.ReviewResponse reported = placeService.complain(
			reporterId,
			place.id(),
			review.id(),
			new PlaceDto.ReviewComplaintRequest("Looks suspicious")
		);

		assertThat(details.averageRating()).isEqualTo(5.0);
		assertThat(details.reviewCount()).isEqualTo(1);
		assertThat(review.status()).isEqualTo(ReviewStatus.PUBLISHED);
		assertThat(reported.complaintCount()).isEqualTo(1);
	}

	@Test
	void reviewTextLengthIsValidated() {
		UUID authorId = registerUser("review-length").user().id();
		UUID placeId = createPlace("Review length place").getId();
		PlaceDto.ReviewUpsertRequest tooShort = new PlaceDto.ReviewUpsertRequest(5, "short");
		PlaceDto.ReviewUpsertRequest tooLong = new PlaceDto.ReviewUpsertRequest(5, "a".repeat(1001));

		assertThatThrownBy(() -> placeService.upsertReview(authorId, placeId, tooShort))
			.isInstanceOf(ApiException.class)
			.hasMessageContaining("Review length is outside configured limits");
		assertThatThrownBy(() -> placeService.upsertReview(authorId, placeId, tooLong))
			.isInstanceOf(ApiException.class)
			.hasMessageContaining("Review length is outside configured limits");
	}

	@Test
	void dailyReviewLimitIsEnforcedForNewReviews() {
		UUID authorId = registerUser("review-limit").user().id();
		List<Place> places = java.util.stream.IntStream.rangeClosed(1, 11)
			.mapToObj(index -> createPlace("Daily limit place " + index))
			.toList();
		PlaceDto.ReviewUpsertRequest request = new PlaceDto.ReviewUpsertRequest(
			5,
			"Useful place with friendly service."
		);

		for (int index = 0; index < 10; index++) {
			placeService.upsertReview(authorId, places.get(index).getId(), request);
		}

		assertThatThrownBy(() -> placeService.upsertReview(authorId, places.get(10).getId(), request))
			.isInstanceOf(ApiException.class)
			.hasMessageContaining("Daily review limit exceeded");
	}

	@Test
	void reviewIsHiddenAfterThreeComplaints() {
		UUID authorId = registerUser("complaint-author").user().id();
		UUID placeId = createPlace("Complaint place").getId();
		PlaceDto.ReviewResponse pendingReview = placeService.upsertReview(
			authorId,
			placeId,
			new PlaceDto.ReviewUpsertRequest(4, "Good place, but the queue was long.")
		);
		PlaceDto.ReviewResponse review = placeService.publishReview(pendingReview.id());
		List<UUID> reporterIds = List.of(
			registerUser("complaint-reporter-1").user().id(),
			registerUser("complaint-reporter-2").user().id(),
			registerUser("complaint-reporter-3").user().id()
		);

		PlaceDto.ReviewResponse reported = null;
		for (UUID reporterId : reporterIds) {
			reported = placeService.complain(
				reporterId,
				placeId,
				review.id(),
				new PlaceDto.ReviewComplaintRequest("Needs moderation")
			);
		}
		PlaceDto.PlaceDetailsResponse details = placeService.getPlace(placeId);

		assertThat(reported).isNotNull();
		assertThat(reported.status()).isEqualTo(ReviewStatus.UNDER_MODERATION);
		assertThat(reported.complaintCount()).isEqualTo(3);
		assertThat(details.reviews()).isEmpty();
		assertThat(details.reviewCount()).isEqualTo(0);
		assertThat(details.averageRating()).isZero();
	}

	@Test
	void adminCanRejectReviewFromModerationQueue() {
		UUID authorId = registerUser("moderation-author").user().id();
		UUID placeId = createPlace("Moderation place").getId();

		PlaceDto.ReviewResponse review = placeService.upsertReview(
			authorId,
			placeId,
			new PlaceDto.ReviewUpsertRequest(4, "Helpful team and clean waiting area.")
		);
		PlaceDto.ReviewResponse rejected = placeService.rejectReview(review.id());

		assertThat(placeService.listReviewsByStatus(ReviewStatus.UNDER_MODERATION))
			.extracting(PlaceDto.ReviewResponse::id)
			.doesNotContain(review.id());
		assertThat(rejected.status()).isEqualTo(ReviewStatus.REJECTED);
		assertThat(placeService.getPlace(placeId).reviews()).isEmpty();
	}

	private Place createPlace(String name) {
		Place place = new Place();
		place.setName(name);
		place.setAddress("Moscow, Test street, " + UUID.randomUUID());
		place.setDescription("Test place");
		place.setCategory(PlaceCategory.OTHER);
		place.setDistrict("Test district");
		place.setMetroStation("Test metro");
		place.setLatitude(55.75);
		place.setLongitude(37.61);
		return placeRepository.save(place);
	}
}
