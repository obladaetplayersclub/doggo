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
@Table(name = "app_user")
public class UserAccount extends BaseEntity {

	@Column(nullable = false, unique = true, length = 320)
	private String email;

	@Column(nullable = false)
	private String passwordHash;

	@Column(nullable = false, length = 120)
	private String displayName;

	@Column(length = 512)
	private String avatarUrl;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false, length = 20)
	private UserRole role = UserRole.USER;
}
