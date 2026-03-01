package com.doggo.dto;

import com.doggo.entity.PetGender;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public final class PetDto {

	private PetDto() {
	}

	public record PetUpsertRequest(
		@NotBlank @Size(max = 120) String name,
		@Size(max = 120) String breed,
		LocalDate birthDate,
		@NotNull PetGender gender,
		@Size(max = 512) String photoUrl,
		@Size(max = 2000) String notes
	) {
	}

	public record AllergyCreateRequest(
		@NotBlank @Size(max = 255) String name
	) {
	}

	public record VaccinationUpsertRequest(
		@NotBlank @Size(max = 255) String name,
		@NotNull LocalDate vaccinationDate,
		@Size(max = 1000) String comment
	) {
	}

	public record AllergyResponse(
		UUID id,
		String name,
		OffsetDateTime createdAt
	) {
	}

	public record VaccinationResponse(
		UUID id,
		String name,
		LocalDate vaccinationDate,
		String comment,
		OffsetDateTime createdAt
	) {
	}

	public record AttachmentResponse(
		UUID id,
		String originalFilename,
		String contentType,
		long sizeBytes,
		String downloadUrl,
		OffsetDateTime createdAt
	) {
	}

	public record PetResponse(
		UUID id,
		String name,
		String breed,
		LocalDate birthDate,
		PetGender gender,
		String photoUrl,
		String notes,
		OffsetDateTime createdAt,
		OffsetDateTime updatedAt,
		List<AllergyResponse> allergies,
		List<VaccinationResponse> vaccinations,
		List<AttachmentResponse> attachments
	) {
	}
}
