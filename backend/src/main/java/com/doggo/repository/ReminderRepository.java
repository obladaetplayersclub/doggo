package com.doggo.repository;

import com.doggo.entity.Reminder;
import com.doggo.entity.ReminderStatus;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReminderRepository extends JpaRepository<Reminder, UUID> {

	List<Reminder> findAllByOwnerIdOrderByScheduledAtAsc(UUID ownerId);

	List<Reminder> findAllByOwnerIdAndStatusOrderByScheduledAtAsc(UUID ownerId, ReminderStatus status);

	Optional<Reminder> findByIdAndOwnerId(UUID reminderId, UUID ownerId);

	List<Reminder> findTop100ByStatusAndNextTriggerAtLessThanEqualOrderByNextTriggerAtAsc(
		ReminderStatus status,
		OffsetDateTime now
	);
}
