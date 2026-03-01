package com.doggo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "reminder")
public class Reminder extends BaseEntity {

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "owner_id", nullable = false)
	private UserAccount owner;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "pet_id", nullable = false)
	private Pet pet;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private ReminderType type;

	@Column(nullable = false, length = 255)
	private String title;

	@Column(nullable = false)
	private OffsetDateTime scheduledAt;

	@Column
	private OffsetDateTime nextTriggerAt;

	@Column
	private OffsetDateTime lastTriggeredAt;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private ReminderRecurrence recurrence = ReminderRecurrence.NONE;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private ReminderStatus status = ReminderStatus.ACTIVE;

	@Column(length = 1000)
	private String comment;

	@Column
	private OffsetDateTime completedAt;
}
