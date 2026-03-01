package com.doggo.exception;

import jakarta.servlet.http.HttpServletRequest;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

@RestControllerAdvice
public class GlobalExceptionHandler {

	@ExceptionHandler(ApiException.class)
	public ResponseEntity<ApiErrorResponse> handleApi(ApiException exception, HttpServletRequest request) {
		return build(exception.getStatus(), exception.getMessage(), request.getRequestURI(), Map.of());
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<ApiErrorResponse> handleValidation(
		MethodArgumentNotValidException exception,
		HttpServletRequest request
	) {
		Map<String, String> errors = new LinkedHashMap<>();
		for (FieldError error : exception.getBindingResult().getFieldErrors()) {
			errors.put(error.getField(), error.getDefaultMessage());
		}
		return build(HttpStatus.BAD_REQUEST, "Validation failed", request.getRequestURI(), errors);
	}

	@ExceptionHandler({
		HttpMessageNotReadableException.class,
		MaxUploadSizeExceededException.class,
		DataIntegrityViolationException.class
	})
	public ResponseEntity<ApiErrorResponse> handleBadRequest(Exception exception, HttpServletRequest request) {
		return build(HttpStatus.BAD_REQUEST, exception.getMessage(), request.getRequestURI(), Map.of());
	}

	@ExceptionHandler(AuthenticationException.class)
	public ResponseEntity<ApiErrorResponse> handleAuthentication(
		AuthenticationException exception,
		HttpServletRequest request
	) {
		return build(HttpStatus.UNAUTHORIZED, exception.getMessage(), request.getRequestURI(), Map.of());
	}

	@ExceptionHandler(AccessDeniedException.class)
	public ResponseEntity<ApiErrorResponse> handleAccessDenied(
		AccessDeniedException exception,
		HttpServletRequest request
	) {
		return build(HttpStatus.FORBIDDEN, "Access denied", request.getRequestURI(), Map.of());
	}

	@ExceptionHandler(Exception.class)
	public ResponseEntity<ApiErrorResponse> handleUnexpected(Exception exception, HttpServletRequest request) {
		return build(
			HttpStatus.INTERNAL_SERVER_ERROR,
			"Unexpected server error",
			request.getRequestURI(),
			Map.of()
		);
	}

	private ResponseEntity<ApiErrorResponse> build(
		HttpStatus status,
		String message,
		String path,
		Map<String, String> validationErrors
	) {
		return ResponseEntity.status(status).body(new ApiErrorResponse(
			OffsetDateTime.now(),
			status.value(),
			status.getReasonPhrase(),
			message,
			path,
			validationErrors
		));
	}
}
