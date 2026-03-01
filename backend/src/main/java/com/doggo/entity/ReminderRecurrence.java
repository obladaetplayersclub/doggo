package com.doggo.entity;

import java.time.OffsetDateTime;

public enum ReminderRecurrence {
	NONE,
	DAILY,
	WEEKLY,
	MONTHLY,
	YEARLY;

	public OffsetDateTime nextFrom(OffsetDateTime value) {
		return switch (this) {
			case DAILY -> value.plusDays(1);
			case WEEKLY -> value.plusWeeks(1);
			case MONTHLY -> value.plusMonths(1);
			case YEARLY -> value.plusYears(1);
			case NONE -> null;
		};
	}
}
