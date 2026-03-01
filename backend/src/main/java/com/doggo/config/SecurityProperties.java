package com.doggo.config;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "app.security")
public record SecurityProperties(
	@NotBlank String jwtSecret,
	@NotNull Duration jwtExpiration,
	@NotBlank String jwtIssuer
) {
}
