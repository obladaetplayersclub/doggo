package com.doggo.repository;

import com.doggo.entity.WalkPoint;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WalkPointRepository extends JpaRepository<WalkPoint, UUID> {

	List<WalkPoint> findAllByWalkIdOrderByRecordedAtAsc(UUID walkId);
}
