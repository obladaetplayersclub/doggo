package com.doggo.walk;

import static org.assertj.core.api.Assertions.assertThat;

import com.doggo.dto.WalkDto;
import com.doggo.service.WalkService;
import com.doggo.support.IntegrationTestSupport;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class WalkServiceIntegrationTest extends IntegrationTestSupport {

	@Autowired
	private WalkService walkService;

	@Test
	void walkAccumulatesDistanceAndStats() {
		UUID ownerId = registerUser("walk").user().id();
		UUID petId = createPet(ownerId, "Lucky").id();
		OffsetDateTime start = OffsetDateTime.now().minusMinutes(20);
		WalkDto.WalkResponse walk = walkService.start(ownerId, petId, new WalkDto.StartWalkRequest(start));
		WalkDto.AddWalkPointsRequest points = new WalkDto.AddWalkPointsRequest(List.of(
			new WalkDto.WalkPointRequest(55.7558, 37.6173, start.plusMinutes(1)),
			new WalkDto.WalkPointRequest(55.7568, 37.6203, start.plusMinutes(5))
		));

		WalkDto.WalkResponse withPoints = walkService.addPoints(ownerId, walk.id(), points);
		WalkDto.WalkResponse finished = walkService.finish(
			ownerId,
			walk.id(),
			new WalkDto.FinishWalkRequest(start.plusMinutes(20))
		);
		WalkDto.WalkStatsResponse stats = walkService.stats(ownerId, petId);

		assertThat(withPoints.distanceMeters()).isGreaterThan(0);
		assertThat(finished.durationSeconds()).isEqualTo(1200);
		assertThat(stats.totalWalks()).isEqualTo(1);
		assertThat(stats.totalDistanceMeters()).isGreaterThan(0);
	}
}
