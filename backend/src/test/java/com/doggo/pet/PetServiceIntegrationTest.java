package com.doggo.pet;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.doggo.dto.PetDto;
import com.doggo.entity.PetGender;
import com.doggo.exception.ApiException;
import com.doggo.support.IntegrationTestSupport;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class PetServiceIntegrationTest extends IntegrationTestSupport {

	@Test
	void petDataIsAvailableOnlyForOwner() {
		UUID ownerId = registerUser("owner").user().id();
		UUID anotherUserId = registerUser("another").user().id();
		PetDto.PetResponse pet = petService.createPet(ownerId, new PetDto.PetUpsertRequest(
			"Buddy",
			"Corgi",
			LocalDate.of(2021, 5, 20),
			PetGender.MALE,
			null,
			"Likes long walks"
		));

		PetDto.PetResponse ownerView = petService.getPet(ownerId, pet.id());

		assertThat(ownerView.name()).isEqualTo("Buddy");
		assertThatThrownBy(() -> petService.getPet(anotherUserId, pet.id()))
			.isInstanceOf(ApiException.class)
			.hasMessageContaining("Pet not found");
	}
}
