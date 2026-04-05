package com.doggo.scheduler;

import com.doggo.config.NotificationProperties;
import com.doggo.service.ReminderService;
import java.time.OffsetDateTime;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class ReminderScheduler {

	private final ReminderService reminderService;
	private final NotificationProperties notificationProperties;

	@Scheduled(fixedDelayString = "${REMINDER_SCHEDULER_DELAY:60000}")
	public void processDueReminders() {
		int processed = reminderService.markDueRemindersTriggered(OffsetDateTime.now());
		if (processed > 0 && notificationProperties.enabled()) {
			log.info("Processed {} due reminders; push provider integration is ready to be attached", processed);
		}
	}
}
