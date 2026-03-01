package com.doggo.repository;

import java.util.UUID;

public interface ReviewRatingProjection {

	UUID getPlaceId();

	Double getAverageRating();

	long getReviewCount();
}
