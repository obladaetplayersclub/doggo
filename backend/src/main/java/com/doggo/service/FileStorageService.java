package com.doggo.service;

import com.doggo.config.StorageProperties;
import com.doggo.exception.ApiException;
import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.text.Normalizer;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class FileStorageService {

	private final StorageProperties storageProperties;
	private MinioClient minioClient;

	@PostConstruct
	void init() {
		if (storageProperties.isS3()) {
			initS3();
			return;
		}

		try {
			Files.createDirectories(storageProperties.uploadPath());
		} catch (IOException exception) {
			throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to initialize file storage");
		}
	}

	public StoredFile store(String namespace, MultipartFile file) {
		if (file.isEmpty()) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Uploaded file is empty");
		}

		String originalFilename = sanitizeFilename(file.getOriginalFilename());
		String storageKey = namespace + "/" + UUID.randomUUID() + "-" + originalFilename;

		try {
			if (storageProperties.isS3()) {
				minioClient.putObject(PutObjectArgs.builder()
					.bucket(storageProperties.bucket())
					.object(storageKey)
					.contentType(file.getContentType())
					.stream(file.getInputStream(), file.getSize(), -1)
					.build());
			} else {
				Path target = resolvePath(storageKey);
				Files.createDirectories(target.getParent());
				Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
			}
			String contentType = file.getContentType() == null ? "application/octet-stream" : file.getContentType();
			return new StoredFile(storageKey, originalFilename, contentType, file.getSize());
		} catch (Exception exception) {
			throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store uploaded file");
		}
	}

	public StoredFileContent load(String storageKey, String contentType) {
		if (storageProperties.isS3()) {
			try (InputStream stream = minioClient.getObject(GetObjectArgs.builder()
				.bucket(storageProperties.bucket())
				.object(storageKey)
				.build())) {
				return new StoredFileContent(stream.readAllBytes(), contentType);
			} catch (Exception exception) {
				throw new ApiException(HttpStatus.NOT_FOUND, "Attachment file not found");
			}
		}

		try {
			Path file = resolvePath(storageKey);
			if (!Files.exists(file)) {
				throw new ApiException(HttpStatus.NOT_FOUND, "Attachment file not found");
			}
			return new StoredFileContent(Files.readAllBytes(file), contentType);
		} catch (IOException exception) {
			throw new ApiException(HttpStatus.NOT_FOUND, "Attachment file not found");
		}
	}

	public void deleteQuietly(String storageKey) {
		if (storageProperties.isS3()) {
			try {
				minioClient.removeObject(RemoveObjectArgs.builder()
					.bucket(storageProperties.bucket())
					.object(storageKey)
					.build());
			} catch (Exception ignored) {
			}
			return;
		}

		try {
			Files.deleteIfExists(resolvePath(storageKey));
		} catch (IOException ignored) {
		}
	}

	private void initS3() {
		try {
			minioClient = MinioClient.builder()
				.endpoint(storageProperties.endpoint())
				.credentials(storageProperties.accessKey(), storageProperties.secretKey())
				.build();
			boolean bucketExists = minioClient.bucketExists(BucketExistsArgs.builder()
				.bucket(storageProperties.bucket())
				.build());
			if (!bucketExists) {
				minioClient.makeBucket(MakeBucketArgs.builder()
					.bucket(storageProperties.bucket())
					.build());
			}
		} catch (Exception exception) {
			throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to initialize S3-compatible storage");
		}
	}

	private Path resolvePath(String storageKey) {
		Path resolved = storageProperties.uploadPath().resolve(storageKey).normalize();
		if (!resolved.startsWith(storageProperties.uploadPath())) {
			throw new ApiException(HttpStatus.BAD_REQUEST, "Invalid storage path");
		}
		return resolved;
	}

	private String sanitizeFilename(String originalFilename) {
		String normalized = originalFilename == null ? "file.bin" : Normalizer.normalize(originalFilename, Normalizer.Form.NFKC);
		String safe = normalized.replaceAll("[^a-zA-Z0-9._-]", "_");
		return safe.isBlank() ? "file.bin" : safe;
	}
}
