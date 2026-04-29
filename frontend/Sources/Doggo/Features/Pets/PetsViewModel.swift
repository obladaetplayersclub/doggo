import Foundation
import Observation

@MainActor
@Observable
public final class PetsViewModel {
	public var pets: [PetResponse] = []
	public var selectedPet: PetResponse?
	public var isLoading = false
	public var errorMessage: String?

	private let apiClient: APIClient

	public init(apiClient: APIClient) {
		self.apiClient = apiClient
	}

	public func loadPets() async {
		isLoading = true
		errorMessage = nil
		defer { isLoading = false }

		do {
			pets = try await apiClient.get("/api/pets")
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func createPet(name: String, breed: String?, gender: PetGender = .unknown) async {
		do {
			let created: PetResponse = try await apiClient.post(
				"/api/pets",
				body: PetUpsertRequest(
					name: name,
					breed: breed,
					birthDate: nil,
					gender: gender,
					photoUrl: nil,
					notes: nil
				)
			)
			pets.insert(created, at: 0)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func createPet(
		name: String,
		breed: String?,
		birthDate: String?,
		gender: PetGender,
		photoUrl: String?,
		notes: String? = nil
	) async {
		do {
			let created: PetResponse = try await apiClient.post(
				"/api/pets",
				body: PetUpsertRequest(
					name: name,
					breed: breed,
					birthDate: birthDate,
					gender: gender,
					photoUrl: photoUrl,
					notes: notes
				)
			)
			pets.insert(created, at: 0)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func updatePet(
		_ pet: PetResponse,
		name: String,
		breed: String?,
		birthDate: String?,
		gender: PetGender,
		photoUrl: String? = nil,
		notes: String? = nil
	) async {
		do {
			let updated: PetResponse = try await apiClient.put(
				"/api/pets/\(pet.id.uuidString)",
				body: PetUpsertRequest(
					name: name,
					breed: breed,
					birthDate: birthDate,
					gender: gender,
					photoUrl: photoUrl ?? pet.photoUrl,
					notes: notes
				)
			)
			if let index = pets.firstIndex(where: { $0.id == pet.id }) {
				pets[index] = updated
			}
			selectedPet = updated
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func deletePet(_ pet: PetResponse) async {
		do {
			try await apiClient.delete("/api/pets/\(pet.id.uuidString)")
			pets.removeAll { $0.id == pet.id }
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func addAllergy(to pet: PetResponse, name: String) async {
		do {
			let _: AllergyResponse = try await apiClient.post(
				"/api/pets/\(pet.id.uuidString)/allergies",
				body: AllergyCreateRequest(name: name)
			)
			await refreshPet(pet.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func deleteAllergy(_ allergy: AllergyResponse, from pet: PetResponse) async {
		do {
			try await apiClient.delete("/api/pets/\(pet.id.uuidString)/allergies/\(allergy.id.uuidString)")
			await refreshPet(pet.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func addVaccination(to pet: PetResponse, name: String, date: String, comment: String?) async {
		do {
			let _: VaccinationResponse = try await apiClient.post(
				"/api/pets/\(pet.id.uuidString)/vaccinations",
				body: VaccinationUpsertRequest(name: name, vaccinationDate: date, comment: comment)
			)
			await refreshPet(pet.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func updateVaccination(
		_ vaccination: VaccinationResponse,
		for pet: PetResponse,
		name: String,
		date: String,
		comment: String?
	) async {
		do {
			let _: VaccinationResponse = try await apiClient.put(
				"/api/pets/\(pet.id.uuidString)/vaccinations/\(vaccination.id.uuidString)",
				body: VaccinationUpsertRequest(name: name, vaccinationDate: date, comment: comment)
			)
			await refreshPet(pet.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func deleteVaccination(_ vaccination: VaccinationResponse, from pet: PetResponse) async {
		do {
			try await apiClient.delete("/api/pets/\(pet.id.uuidString)/vaccinations/\(vaccination.id.uuidString)")
			await refreshPet(pet.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func uploadAttachment(to pet: PetResponse, data: Data, filename: String, contentType: String) async {
		do {
			let _: AttachmentResponse = try await apiClient.uploadMultipart(
				"/api/pets/\(pet.id.uuidString)/attachments",
				fileData: data,
				filename: filename,
				contentType: contentType
			)
			await refreshPet(pet.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func deleteAttachment(_ attachment: AttachmentResponse, from pet: PetResponse) async {
		do {
			try await apiClient.delete("/api/pets/\(pet.id.uuidString)/attachments/\(attachment.id.uuidString)")
			await refreshPet(pet.id)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	public func refreshPet(_ petId: UUID) async {
		do {
			let updated: PetResponse = try await apiClient.get("/api/pets/\(petId.uuidString)")
			replacePet(updated)
		} catch {
			errorMessage = error.localizedDescription
		}
	}

	private func replacePet(_ pet: PetResponse) {
		if let index = pets.firstIndex(where: { $0.id == pet.id }) {
			pets[index] = pet
		} else {
			pets.insert(pet, at: 0)
		}
		selectedPet = pet
	}
}
