package com.doggo.config;

import jakarta.validation.constraints.Min;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "app.reviews")
public record ReviewProperties(
	@Min(1) int dailyLimit,
	@Min(1) int minLength,
	@Min(1) int maxLength
) {
}
