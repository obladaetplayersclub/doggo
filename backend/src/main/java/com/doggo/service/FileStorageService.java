package com.doggo.service;

import com.doggo.config.StorageProperties;
import com.doggo.exception.ApiException;
import jakarta.annotation.PostConstruct;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.text.Normalizer;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class FileStorageService {

	private final StorageProperties storageProperties;

	@PostConstruct
	void init() {
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
		Path target = resolvePath(storageKey);

		try {
			Files.createDirectories(target.getParent());
			Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
			String contentType = file.getContentType() == null ? "application/octet-stream" : file.getContentType();
			return new StoredFile(storageKey, originalFilename, contentType, file.getSize());
		} catch (IOException exception) {
			throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to store uploaded file");
		}
	}

	public Resource loadAsResource(String storageKey) {
		try {
			Path file = resolvePath(storageKey);
			Resource resource = new UrlResource(file.toUri());
			if (!resource.exists()) {
				throw new ApiException(HttpStatus.NOT_FOUND, "Attachment file not found");
			}
			return resource;
		} catch (java.net.MalformedURLException exception) {
			throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to load stored file");
		}
	}

	public void deleteQuietly(String storageKey) {
		try {
			Files.deleteIfExists(resolvePath(storageKey));
		} catch (IOException ignored) {
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
