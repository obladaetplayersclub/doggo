package com.doggo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "pet_attachment")
public class PetAttachment extends BaseEntity {

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "pet_id", nullable = false)
	private Pet pet;

	@Column(nullable = false, length = 255)
	private String originalFilename;

	@Column(nullable = false, length = 255)
	private String storageKey;

	@Column(nullable = false, length = 255)
	private String contentType;

	@Column(nullable = false)
	private long sizeBytes;
}
