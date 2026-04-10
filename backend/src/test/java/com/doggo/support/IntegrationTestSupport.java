package com.doggo.support;

import com.doggo.dto.AuthDto;
import com.doggo.dto.PetDto;
import com.doggo.entity.PetGender;
import com.doggo.service.AuthService;
import com.doggo.service.PetService;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
public abstract class IntegrationTestSupport {

	@Autowired
	protected AuthService authService;

	@Autowired
	protected PetService petService;

	protected AuthDto.AuthResponse registerUser(String prefix) {
		return authService.register(new AuthDto.RegisterRequest(uniqueEmail(prefix), "strong-password", prefix));
	}

	protected PetDto.PetResponse createPet(UUID ownerId, String name) {
		return petService.createPet(ownerId, new PetDto.PetUpsertRequest(
			name,
			null,
			null,
			PetGender.UNKNOWN,
			null,
			null
		));
	}

	protected String uniqueEmail() {
		return uniqueEmail("user");
	}

	protected String uniqueEmail(String prefix) {
		return prefix + "-" + UUID.randomUUID() + "@example.com";
	}
}
