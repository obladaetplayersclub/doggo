package com.doggo.repository;

import com.doggo.entity.Pet;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PetRepository extends JpaRepository<Pet, UUID> {

	List<Pet> findAllByOwnerIdOrderByCreatedAtDesc(UUID ownerId);

	Optional<Pet> findByIdAndOwnerId(UUID petId, UUID ownerId);
}
