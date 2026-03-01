package com.doggo.repository;

import com.doggo.entity.Walk;
import com.doggo.entity.WalkStatus;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WalkRepository extends JpaRepository<Walk, UUID> {

	List<Walk> findAllByOwnerIdAndPetIdOrderByStartedAtDesc(UUID ownerId, UUID petId);

	Optional<Walk> findByIdAndOwnerId(UUID walkId, UUID ownerId);

	Optional<Walk> findByPetIdAndStatus(UUID petId, WalkStatus status);
}
