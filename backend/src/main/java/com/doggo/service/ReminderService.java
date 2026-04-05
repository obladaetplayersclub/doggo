package com.doggo.service;

import com.doggo.dto.ReminderDto;
import com.doggo.entity.Pet;
import com.doggo.entity.Reminder;
import com.doggo.entity.ReminderStatus;
import com.doggo.entity.UserAccount;
import com.doggo.exception.ApiException;
import com.doggo.repository.ReminderRepository;
import com.doggo.repository.UserAccountRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ReminderService {

	private final ReminderRepository reminderRepository;
	private final UserAccountRepository userAccountRepository;
	private final PetService petService;

	public List<ReminderDto.ReminderResponse> list(UUID ownerId, ReminderStatus status) {
		List<Reminder> reminders = status == null
			? reminderRepository.findAllByOwnerIdOrderByScheduledAtAsc(ownerId)
			: reminderRepository.findAllByOwnerIdAndStatusOrderByScheduledAtAsc(ownerId, status);
		return reminders.stream().map(this::toResponse).toList();
	}

	public ReminderDto.ReminderResponse get(UUID ownerId, UUID reminderId) {
		return toResponse(getOwnedReminder(ownerId, reminderId));
	}

	@Transactional
	public ReminderDto.ReminderResponse create(UUID ownerId, ReminderDto.ReminderUpsertRequest request) {
		UserAccount owner = userAccountRepository.findById(ownerId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
		Pet pet = petService.getOwnedPet(ownerId, request.petId());

		Reminder reminder = new Reminder();
		reminder.setOwner(owner);
		reminder.setPet(pet);
		applyRequest(reminder, request);
		return toResponse(reminderRepository.save(reminder));
	}

	@Transactional
	public ReminderDto.ReminderResponse update(UUID ownerId, UUID reminderId, ReminderDto.ReminderUpsertRequest request) {
		Reminder reminder = getOwnedReminder(ownerId, reminderId);
		Pet pet = petService.getOwnedPet(ownerId, request.petId());
		reminder.setPet(pet);
		applyRequest(reminder, request);
		return toResponse(reminder);
	}

	@Transactional
	public ReminderDto.ReminderResponse complete(UUID ownerId, UUID reminderId) {
		Reminder reminder = getOwnedReminder(ownerId, reminderId);
		reminder.setStatus(ReminderStatus.COMPLETED);
		reminder.setCompletedAt(OffsetDateTime.now());
		reminder.setNextTriggerAt(null);
		return toResponse(reminder);
	}

	@Transactional
	public void delete(UUID ownerId, UUID reminderId) {
		Reminder reminder = getOwnedReminder(ownerId, reminderId);
		reminderRepository.delete(reminder);
	}

	@Transactional
	public int markDueRemindersTriggered(OffsetDateTime now) {
		List<Reminder> dueReminders = reminderRepository
			.findTop100ByStatusAndNextTriggerAtLessThanEqualOrderByNextTriggerAtAsc(ReminderStatus.ACTIVE, now);
		for (Reminder reminder : dueReminders) {
			reminder.setLastTriggeredAt(now);
			OffsetDateTime next = reminder.getRecurrence().nextFrom(reminder.getNextTriggerAt());
			if (next == null) {
				reminder.setStatus(ReminderStatus.COMPLETED);
				reminder.setCompletedAt(now);
			}
			reminder.setNextTriggerAt(next);
		}
		return dueReminders.size();
	}

	private Reminder getOwnedReminder(UUID ownerId, UUID reminderId) {
		return reminderRepository.findByIdAndOwnerId(reminderId, ownerId)
			.orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Reminder not found"));
	}

	private void applyRequest(Reminder reminder, ReminderDto.ReminderUpsertRequest request) {
		reminder.setType(request.type());
		reminder.setTitle(request.title().trim());
		reminder.setScheduledAt(request.scheduledAt());
		reminder.setNextTriggerAt(request.scheduledAt());
		reminder.setRecurrence(request.recurrence());
		reminder.setStatus(ReminderStatus.ACTIVE);
		reminder.setCompletedAt(null);
		reminder.setComment(blankToNull(request.comment()));
	}

	private ReminderDto.ReminderResponse toResponse(Reminder reminder) {
		return new ReminderDto.ReminderResponse(
			reminder.getId(),
			reminder.getPet().getId(),
			reminder.getPet().getName(),
			reminder.getType(),
			reminder.getTitle(),
			reminder.getScheduledAt(),
			reminder.getNextTriggerAt(),
			reminder.getLastTriggeredAt(),
			reminder.getRecurrence(),
			reminder.getStatus(),
			reminder.getComment(),
			reminder.getCompletedAt()
		);
	}

	private String blankToNull(String value) {
		return value == null || value.isBlank() ? null : value.trim();
	}
}
