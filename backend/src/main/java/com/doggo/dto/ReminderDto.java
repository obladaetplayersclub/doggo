package com.doggo.dto;

import com.doggo.entity.ReminderRecurrence;
import com.doggo.entity.ReminderStatus;
import com.doggo.entity.ReminderType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.OffsetDateTime;
import java.util.UUID;

public final class ReminderDto {

	private ReminderDto() {
	}

	public record ReminderUpsertRequest(
		@NotNull UUID petId,
		@NotNull ReminderType type,
		@NotBlank @Size(max = 255) String title,
		@NotNull OffsetDateTime scheduledAt,
		@NotNull ReminderRecurrence recurrence,
		@Size(max = 1000) String comment
	) {
	}

	public record ReminderResponse(
		UUID id,
		UUID petId,
		String petName,
		ReminderType type,
		String title,
		OffsetDateTime scheduledAt,
		OffsetDateTime nextTriggerAt,
		OffsetDateTime lastTriggeredAt,
		ReminderRecurrence recurrence,
		ReminderStatus status,
		String comment,
		OffsetDateTime completedAt
	) {
	}
}
