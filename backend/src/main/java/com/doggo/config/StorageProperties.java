package com.doggo.config;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import java.nio.file.Path;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "app.storage")
public record StorageProperties(
	@NotBlank String type,
	@NotBlank String localDir,
	String endpoint,
	@NotBlank String bucket,
	@NotBlank String region,
	String accessKey,
	String secretKey
) {

	public Path uploadPath() {
		return Path.of(localDir).toAbsolutePath().normalize();
	}

	public boolean isS3() {
		return "s3".equalsIgnoreCase(type);
	}

	public boolean isLocal() {
		return "local".equalsIgnoreCase(type);
	}

	@AssertTrue(message = "app.storage.type must be either 's3' or 'local'")
	public boolean isSupportedType() {
		return isS3() || isLocal();
	}

	@AssertTrue(message = "S3 storage requires endpoint, access-key and secret-key")
	public boolean isS3ConfigurationComplete() {
		return isLocal()
			|| notBlank(endpoint) && notBlank(accessKey) && notBlank(secretKey);
	}

	private boolean notBlank(String value) {
		return value != null && !value.isBlank();
	}
}
