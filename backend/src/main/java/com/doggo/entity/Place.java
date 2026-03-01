package com.doggo.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "place")
public class Place extends BaseEntity {

	@Column(nullable = false, length = 255)
	private String name;

	@Column(nullable = false, length = 512)
	private String address;

	@Column(length = 1000)
	private String description;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 30)
	private PlaceCategory category;

	@Column(length = 120)
	private String district;

	@Column(length = 120)
	private String metroStation;

	@Column(nullable = false)
	private double latitude;

	@Column(nullable = false)
	private double longitude;
}
