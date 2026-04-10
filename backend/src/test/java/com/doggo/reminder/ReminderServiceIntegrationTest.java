package com.doggo.reminder;

import static org.assertj.core.api.Assertions.assertThat;

import com.doggo.dto.ReminderDto;
import com.doggo.entity.ReminderRecurrence;
import com.doggo.entity.ReminderStatus;
import com.doggo.entity.ReminderType;
import com.doggo.service.ReminderService;
import com.doggo.support.IntegrationTestSupport;
import java.time.OffsetDateTime;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class ReminderServiceIntegrationTest extends IntegrationTestSupport {

	@Autowired
	private ReminderService reminderService;

	@Test
	void reminderCanBeCreatedAndCompleted() {
		UUID ownerId = registerUser("reminder").user().id();
		UUID petId = createPet(ownerId, "Rex").id();
		ReminderDto.ReminderUpsertRequest request = new ReminderDto.ReminderUpsertRequest(
			petId,
			ReminderType.VACCINATION,
			"Rabies vaccine",
			OffsetDateTime.now().plusDays(1),
			ReminderRecurrence.YEARLY,
			"Vet passport"
		);

		ReminderDto.ReminderResponse created = reminderService.create(ownerId, request);
		ReminderDto.ReminderResponse completed = reminderService.complete(ownerId, created.id());

		assertThat(created.status()).isEqualTo(ReminderStatus.ACTIVE);
		assertThat(completed.status()).isEqualTo(ReminderStatus.COMPLETED);
		assertThat(completed.completedAt()).isNotNull();
	}
}
