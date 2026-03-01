package com.doggo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDate;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "pet")
public class Pet extends BaseEntity {

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "owner_id", nullable = false)
	private UserAccount owner;

	@Column(nullable = false, length = 120)
	private String name;

	@Column(length = 120)
	private String breed;

	private LocalDate birthDate;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private PetGender gender = PetGender.UNKNOWN;

	@Column(length = 512)
	private String photoUrl;

	@Column(length = 2000)
	private String notes;
}
