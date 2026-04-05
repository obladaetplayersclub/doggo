package com.doggo.controller;

import com.doggo.dto.ReminderDto;
import com.doggo.entity.ReminderStatus;
import com.doggo.security.AuthenticatedUser;
import com.doggo.service.ReminderService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/reminders")
public class ReminderController {

	private final ReminderService reminderService;

	@GetMapping
	public List<ReminderDto.ReminderResponse> list(
		@AuthenticationPrincipal AuthenticatedUser user,
		@RequestParam(required = false) ReminderStatus status
	) {
		return reminderService.list(user.id(), status);
	}

	@PostMapping
	@ResponseStatus(HttpStatus.CREATED)
	public ReminderDto.ReminderResponse create(
		@AuthenticationPrincipal AuthenticatedUser user,
		@Valid @RequestBody ReminderDto.ReminderUpsertRequest request
	) {
		return reminderService.create(user.id(), request);
	}

	@GetMapping("/{reminderId}")
	public ReminderDto.ReminderResponse get(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID reminderId
	) {
		return reminderService.get(user.id(), reminderId);
	}

	@PutMapping("/{reminderId}")
	public ReminderDto.ReminderResponse update(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID reminderId,
		@Valid @RequestBody ReminderDto.ReminderUpsertRequest request
	) {
		return reminderService.update(user.id(), reminderId, request);
	}

	@PostMapping("/{reminderId}/complete")
	public ReminderDto.ReminderResponse complete(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID reminderId
	) {
		return reminderService.complete(user.id(), reminderId);
	}

	@DeleteMapping("/{reminderId}")
	@ResponseStatus(HttpStatus.NO_CONTENT)
	public void delete(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID reminderId) {
		reminderService.delete(user.id(), reminderId);
	}
}
