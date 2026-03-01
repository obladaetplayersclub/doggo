package com.doggo.repository;

import com.doggo.entity.PetVaccination;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PetVaccinationRepository extends JpaRepository<PetVaccination, UUID> {

	List<PetVaccination> findAllByPetIdOrderByVaccinationDateDesc(UUID petId);

	Optional<PetVaccination> findByIdAndPetId(UUID vaccinationId, UUID petId);
}
