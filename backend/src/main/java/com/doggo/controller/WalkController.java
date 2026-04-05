package com.doggo.controller;

import com.doggo.dto.WalkDto;
import com.doggo.security.AuthenticatedUser;
import com.doggo.service.WalkService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class WalkController {

	private final WalkService walkService;

	@GetMapping("/pets/{petId}/walks")
	public List<WalkDto.WalkResponse> listWalks(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId
	) {
		return walkService.list(user.id(), petId);
	}

	@PostMapping("/pets/{petId}/walks")
	@ResponseStatus(HttpStatus.CREATED)
	public WalkDto.WalkResponse startWalk(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId,
		@Valid @RequestBody WalkDto.StartWalkRequest request
	) {
		return walkService.start(user.id(), petId, request);
	}

	@PostMapping("/walks/{walkId}/points")
	public WalkDto.WalkResponse addPoints(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID walkId,
		@Valid @RequestBody WalkDto.AddWalkPointsRequest request
	) {
		return walkService.addPoints(user.id(), walkId, request);
	}

	@PostMapping("/walks/{walkId}/finish")
	public WalkDto.WalkResponse finishWalk(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID walkId,
		@Valid @RequestBody WalkDto.FinishWalkRequest request
	) {
		return walkService.finish(user.id(), walkId, request);
	}

	@GetMapping("/pets/{petId}/walks/stats")
	public WalkDto.WalkStatsResponse stats(
		@AuthenticationPrincipal AuthenticatedUser user,
		@PathVariable UUID petId
	) {
		return walkService.stats(user.id(), petId);
	}
}
