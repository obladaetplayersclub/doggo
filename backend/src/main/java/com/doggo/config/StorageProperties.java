package com.doggo.config;

import jakarta.validation.constraints.NotBlank;
import java.nio.file.Path;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "app.storage")
public record StorageProperties(@NotBlank String uploadDir) {

	public Path uploadPath() {
		return Path.of(uploadDir).toAbsolutePath().normalize();
	}
}
