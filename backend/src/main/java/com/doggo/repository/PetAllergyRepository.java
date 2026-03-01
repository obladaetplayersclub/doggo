package com.doggo.repository;

import com.doggo.entity.PetAllergy;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PetAllergyRepository extends JpaRepository<PetAllergy, UUID> {

	List<PetAllergy> findAllByPetIdOrderByCreatedAtAsc(UUID petId);

	Optional<PetAllergy> findByIdAndPetId(UUID allergyId, UUID petId);
}
