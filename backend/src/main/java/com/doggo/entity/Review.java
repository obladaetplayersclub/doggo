package com.doggo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "review")
public class Review extends BaseEntity {

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "place_id", nullable = false)
	private Place place;

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "author_id", nullable = false)
	private UserAccount author;

	@Column(nullable = false)
	private int rating;

	@Column(nullable = false, length = 1000)
	private String text;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 30)
	private ReviewStatus status = ReviewStatus.UNDER_MODERATION;

	@Column(nullable = false)
	private int complaintCount = 0;
}
