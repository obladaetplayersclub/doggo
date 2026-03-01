package com.doggo.repository;

import com.doggo.entity.ReviewComplaint;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReviewComplaintRepository extends JpaRepository<ReviewComplaint, UUID> {

	boolean existsByReviewIdAndReporterId(UUID reviewId, UUID reporterId);
}
