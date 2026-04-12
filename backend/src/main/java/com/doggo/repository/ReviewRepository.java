package com.doggo.repository;

import com.doggo.entity.Review;
import com.doggo.entity.ReviewStatus;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ReviewRepository extends JpaRepository<Review, UUID> {

	List<Review> findAllByPlaceIdAndStatusOrderByCreatedAtDesc(UUID placeId, ReviewStatus status);

	List<Review> findAllByStatusOrderByCreatedAtDesc(ReviewStatus status);

	Optional<Review> findByIdAndPlaceId(UUID reviewId, UUID placeId);

	Optional<Review> findByPlaceIdAndAuthorId(UUID placeId, UUID authorId);

	long countByAuthorIdAndCreatedAtBetween(UUID authorId, OffsetDateTime start, OffsetDateTime end);

	long countByPlaceIdAndStatus(UUID placeId, ReviewStatus status);

	@Query("""
		select r.place.id as placeId, avg(r.rating) as averageRating, count(r.id) as reviewCount
		from Review r
		where r.status = :status and r.place.id in :placeIds
		group by r.place.id
	""")
	List<ReviewRatingProjection> summarizePublishedRatings(
		@Param("placeIds") List<UUID> placeIds,
		@Param("status") ReviewStatus status
	);
}
