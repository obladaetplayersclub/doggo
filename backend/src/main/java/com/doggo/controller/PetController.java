package com.doggo.controller;

import com.doggo.dto.PetDto;
import com.doggo.entity.PetAttachment;
import com.doggo.security.AuthenticatedUser;
import com.doggo.service.FileStorageService;
import com.doggo.service.PetService;
import com.doggo.service.StoredFileContent;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/pets")
public class PetController {

	private final PetService petService;
	private final FileStorageService fileStorageService;

	@GetMapping
	public List<PetDto.PetResponse> listPets(@AuthenticationPrincipal AuthenticatedUser user) {
		return petService.listPets(user.id());
	}

	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public PetDto.PetResponse createPet(
		@AuthenticationPrincipal AuthenticatedUser user,
		@Valid @RequestBody PetDto.PetUpsertRequest request
	) {
		return petService.createPet(user.id(), request);
	}

	@GetMapping("/{petId}")
	public PetDto.PetResponse getPet(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID petId) {
		return petService.getPet(user.id(), petId);
	}

	@PutMapping("/{petId}")
	public PetDto.PetResponse updatePet(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@Valid @RequestBody PetDto.PetUpsertRequest request
	) {
		return petService.updatePet(user.id(), petId, request);
	}

	@DeleteMapping("/{petId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void deletePet(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID petId) {
		petService.deletePet(user.id(), petId);
	}

	@GetMapping("/{petId}/allergies")
	public List<PetDto.AllergyResponse> listAllergies(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId
	) {
		return petService.listAllergies(user.id(), petId);
	}

	@PostMapping("/{petId}/allergies")
	@ResponseStatus(HttpStatus.CREATED)
	public PetDto.AllergyResponse addAllergy(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@Valid @RequestBody PetDto.AllergyCreateRequest request
	) {
		return petService.addAllergy(user.id(), petId, request);
	}

	@DeleteMapping("/{petId}/allergies/{allergyId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void deleteAllergy(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@PathVariable UUID allergyId
	) {
		petService.deleteAllergy(user.id(), petId, allergyId);
	}

	@GetMapping("/{petId}/vaccinations")
	public List<PetDto.VaccinationResponse> listVaccinations(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId
	) {
		return petService.listVaccinations(user.id(), petId);
	}

	@PostMapping("/{petId}/vaccinations")
	@ResponseStatus(HttpStatus.CREATED)
	public PetDto.VaccinationResponse addVaccination(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@Valid @RequestBody PetDto.VaccinationUpsertRequest request
	) {
		return petService.addVaccination(user.id(), petId, request);
	}

	@PutMapping("/{petId}/vaccinations/{vaccinationId}")
	public PetDto.VaccinationResponse updateVaccination(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@PathVariable UUID vaccinationId,
		@Valid @RequestBody PetDto.VaccinationUpsertRequest request
	) {
		return petService.updateVaccination(user.id(), petId, vaccinationId, request);
	}

	@DeleteMapping("/{petId}/vaccinations/{vaccinationId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void deleteVaccination(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@PathVariable UUID vaccinationId
	) {
		petService.deleteVaccination(user.id(), petId, vaccinationId);
	}

	@GetMapping("/{petId}/attachments")
	public List<PetDto.AttachmentResponse> listAttachments(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId
	) {
		return petService.listAttachments(user.id(), petId);
	}

	@PostMapping(value = "/{petId}/attachments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
	@ResponseStatus(HttpStatus.CREATED)
	public PetDto.AttachmentResponse uploadAttachment(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@RequestParam("file") MultipartFile file
	) {
		return petService.uploadAttachment(user.id(), petId, file);
	}

	@GetMapping("/{petId}/attachments/{attachmentId}/download")
	public ResponseEntity<byte[]> downloadAttachment(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@PathVariable UUID attachmentId
	) {
		PetAttachment attachment = petService.getOwnedAttachment(user.id(), petId, attachmentId);
		StoredFileContent content = fileStorageService.load(attachment.getStorageKey(), attachment.getContentType());
		return ResponseEntity.ok()
			.contentType(MediaType.parseMediaType(content.contentType()))
			.header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + attachment.getOriginalFilename() + "\"")
			.body(content.bytes());
	}

	@DeleteMapping("/{petId}/attachments/{attachmentId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void deleteAttachment(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@PathVariable UUID attachmentId
	) {
		petService.deleteAttachment(user.id(), petId, attachmentId);
	}
}
