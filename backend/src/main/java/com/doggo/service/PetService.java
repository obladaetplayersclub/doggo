package com.doggo.service;

import com.doggo.dto.PetDto;
import com.doggo.entity.Pet;
import com.doggo.entity.PetAllergy;
import com.doggo.entity.PetAttachment;
import com.doggo.entity.PetVaccination;
import com.doggo.entity.UserAccount;
import com.doggo.exception.ApiException;
import com.doggo.repository.PetAllergyRepository;
import com.doggo.repository.PetAttachmentRepository;
import com.doggo.repository.PetRepository;
import com.doggo.repository.PetVaccinationRepository;
import com.doggo.repository.UserAccountRepository;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class PetService {

	private final UserAccountRepository userAccountRepository;
	private final PetRepository petRepository;
	private final PetAllergyRepository allergyRepository;
	private final PetVaccinationRepository vaccinationRepository;
	private final PetAttachmentRepository attachmentRepository;
	private final FileStorageService fileStorageService;

	public List<PetDto.PetResponse> listPets(UUID ownerId) {
		return petRepository.findAllByOwnerIdOrderByCreatedAtDesc(ownerId).stream()
			.map(this::toResponse)
			.toList();
	}

	public PetDto.PetResponse getPet(UUID ownerId, UUID petId) {
		return toResponse(getOwnedPet(ownerId, petId));
	}

	@Transactional
	public PetDto.PetResponse createPet(UUID ownerId, PetDto.PetUpsertRequest request) {
		UserAccount owner = userAccountRepository.findById(ownerId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

		Pet pet = new Pet();
		pet.setOwner(owner);
		applyRequest(pet, request);
		return toResponse(petRepository.save(pet));
	}

	@Transactional
	public PetDto.PetResponse updatePet(UUID ownerId, UUID petId, PetDto.PetUpsertRequest request) {
		Pet pet = getOwnedPet(ownerId, petId);
		applyRequest(pet, request);
		return toResponse(pet);
	}

	@Transactional
	public void deletePet(UUID ownerId, UUID petId) {
		Pet pet = getOwnedPet(ownerId, petId);
		attachmentRepository.findAllByPetIdOrderByCreatedAtDesc(petId)
			.forEach(attachment -> fileStorageService.deleteQuietly(attachment.getStorageKey()));
		petRepository.delete(pet);
	}

	@Transactional
	public PetDto.AllergyResponse addAllergy(UUID ownerId, UUID petId, PetDto.AllergyCreateRequest request) {
		Pet pet = getOwnedPet(ownerId, petId);
		PetAllergy allergy = new PetAllergy();
		allergy.setPet(pet);
		allergy.setName(request.name().trim());
		return toAllergyResponse(allergyRepository.save(allergy));
	}

	public List<PetDto.AllergyResponse> listAllergies(UUID ownerId, UUID petId) {
		getOwnedPet(ownerId, petId);
		return allergyRepository.findAllByPetIdOrderByCreatedAtAsc(petId).stream()
			.map(this::toAllergyResponse)
			.toList();
	}

	@Transactional
	public void deleteAllergy(UUID ownerId, UUID petId, UUID allergyId) {
		getOwnedPet(ownerId, petId);
		PetAllergy allergy = allergyRepository.findByIdAndPetId(allergyId, petId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Allergy not found"));
		allergyRepository.delete(allergy);
	}

	@Transactional
	public PetDto.VaccinationResponse addVaccination(
		UUID ownerId,
		UUID petId,
		PetDto.VaccinationUpsertRequest request
	) {
		Pet pet = getOwnedPet(ownerId, petId);
		PetVaccination vaccination = new PetVaccination();
		vaccination.setPet(pet);
		applyVaccinationRequest(vaccination, request);
		return toVaccinationResponse(vaccinationRepository.save(vaccination));
	}

	public List<PetDto.VaccinationResponse> listVaccinations(UUID ownerId, UUID petId) {
		getOwnedPet(ownerId, petId);
		return vaccinationRepository.findAllByPetIdOrderByVaccinationDateDesc(petId).stream()
			.map(this::toVaccinationResponse)
			.toList();
	}

	@Transactional
	public PetDto.VaccinationResponse updateVaccination(
		UUID ownerId,
		UUID petId,
		UUID vaccinationId,
		PetDto.VaccinationUpsertRequest request
	) {
		getOwnedPet(ownerId, petId);
		PetVaccination vaccination = vaccinationRepository.findByIdAndPetId(vaccinationId, petId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Vaccination not found"));
		applyVaccinationRequest(vaccination, request);
		return toVaccinationResponse(vaccination);
	}

	@Transactional
	public void deleteVaccination(UUID ownerId, UUID petId, UUID vaccinationId) {
		getOwnedPet(ownerId, petId);
		PetVaccination vaccination = vaccinationRepository.findByIdAndPetId(vaccinationId, petId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Vaccination not found"));
		vaccinationRepository.delete(vaccination);
	}

	@Transactional
	public PetDto.AttachmentResponse uploadAttachment(UUID ownerId, UUID petId, MultipartFile file) {
		Pet pet = getOwnedPet(ownerId, petId);
		StoredFile storedFile = fileStorageService.store("pets/" + petId, file);

		PetAttachment attachment = new PetAttachment();
		attachment.setPet(pet);
		attachment.setOriginalFilename(storedFile.originalFilename());
		attachment.setStorageKey(storedFile.storageKey());
		attachment.setContentType(storedFile.contentType());
		attachment.setSizeBytes(storedFile.sizeBytes());
		return toAttachmentResponse(attachmentRepository.save(attachment));
	}

	public List<PetDto.AttachmentResponse> listAttachments(UUID ownerId, UUID petId) {
		getOwnedPet(ownerId, petId);
		return attachmentRepository.findAllByPetIdOrderByCreatedAtDesc(petId).stream()
			.map(this::toAttachmentResponse)
			.toList();
	}

	public PetAttachment getOwnedAttachment(UUID ownerId, UUID petId, UUID attachmentId) {
		getOwnedPet(ownerId, petId);
		return attachmentRepository.findByIdAndPetId(attachmentId, petId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Attachment not found"));
	}

	@Transactional
	public void deleteAttachment(UUID ownerId, UUID petId, UUID attachmentId) {
		PetAttachment attachment = getOwnedAttachment(ownerId, petId, attachmentId);
		attachmentRepository.delete(attachment);
		fileStorageService.deleteQuietly(attachment.getStorageKey());
	}

	public Pet getOwnedPet(UUID ownerId, UUID petId) {
		return petRepository.findByIdAndOwnerId(petId, ownerId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Pet not found"));
	}

	private void applyRequest(Pet pet, PetDto.PetUpsertRequest request) {
		pet.setName(request.name().trim());
		pet.setBreed(blankToNull(request.breed()));
		pet.setBirthDate(request.birthDate());
		pet.setGender(request.gender());
		pet.setPhotoUrl(blankToNull(request.photoUrl()));
		pet.setNotes(blankToNull(request.notes()));
	}

	private void applyVaccinationRequest(PetVaccination vaccination, PetDto.VaccinationUpsertRequest request) {
		vaccination.setName(request.name().trim());
		vaccination.setVaccinationDate(request.vaccinationDate());
		vaccination.setComment(blankToNull(request.comment()));
	}

	private PetDto.PetResponse toResponse(Pet pet) {
		return new PetDto.PetResponse(
			pet.getId(),
			pet.getName(),
			pet.getBreed(),
			pet.getBirthDate(),
			pet.getGender(),
			pet.getPhotoUrl(),
			pet.getNotes(),
			pet.getCreatedAt(),
			pet.getUpdatedAt(),
			allergyRepository.findAllByPetIdOrderByCreatedAtAsc(pet.getId()).stream().map(this::toAllergyResponse).toList(),
			vaccinationRepository.findAllByPetIdOrderByVaccinationDateDesc(pet.getId()).stream().map(this::toVaccinationResponse).toList(),
			attachmentRepository.findAllByPetIdOrderByCreatedAtDesc(pet.getId()).stream().map(this::toAttachmentResponse).toList()
		);
	}

	private PetDto.AllergyResponse toAllergyResponse(PetAllergy allergy) {
		return new PetDto.AllergyResponse(allergy.getId(), allergy.getName(), allergy.getCreatedAt());
	}

	private PetDto.VaccinationResponse toVaccinationResponse(PetVaccination vaccination) {
		return new PetDto.VaccinationResponse(
			vaccination.getId(),
			vaccination.getName(),
			vaccination.getVaccinationDate(),
			vaccination.getComment(),
			vaccination.getCreatedAt()
		);
	}

	private PetDto.AttachmentResponse toAttachmentResponse(PetAttachment attachment) {
		return new PetDto.AttachmentResponse(
			attachment.getId(),
			attachment.getOriginalFilename(),
			attachment.getContentType(),
			attachment.getSizeBytes(),
			"/api/pets/" + attachment.getPet().getId() + "/attachments/" + attachment.getId() + "/download",
			attachment.getCreatedAt()
		);
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
