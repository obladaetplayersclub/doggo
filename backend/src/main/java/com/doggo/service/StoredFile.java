package com.doggo.service;

public record StoredFile(
	String storageKey,
	String originalFilename,
	String contentType,
	long sizeBytes
) {
}
