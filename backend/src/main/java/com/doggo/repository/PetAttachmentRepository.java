package com.doggo.repository;

import com.doggo.entity.PetAttachment;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PetAttachmentRepository extends JpaRepository<PetAttachment, UUID> {

	List<PetAttachment> findAllByPetIdOrderByCreatedAtDesc(UUID petId);

	Optional<PetAttachment> findByIdAndPetId(UUID attachmentId, UUID petId);
}
