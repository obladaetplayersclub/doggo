package com.doggo.service;

public record StoredFileContent(
	byte[] bytes,
	String contentType
) {
}
