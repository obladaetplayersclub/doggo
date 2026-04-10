package com.doggo.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.doggo.dto.AuthDto;
import com.doggo.support.IntegrationTestSupport;
import org.junit.jupiter.api.Test;

class AuthServiceIntegrationTest extends IntegrationTestSupport {

	@Test
	void registerAndLoginReturnsJwtToken() {
		String email = uniqueEmail();
		AuthDto.RegisterRequest registerRequest = new AuthDto.RegisterRequest(email, "strong-password", "Konstantin");
		AuthDto.LoginRequest loginRequest = new AuthDto.LoginRequest(email, "strong-password");

		AuthDto.AuthResponse registerResponse = authService.register(registerRequest);
		AuthDto.AuthResponse loginResponse = authService.login(loginRequest);

		assertThat(registerResponse.token()).isNotBlank();
		assertThat(registerResponse.user().email()).isEqualTo(email);
		assertThat(loginResponse.token()).isNotBlank();
		assertThat(loginResponse.user().id()).isEqualTo(registerResponse.user().id());
	}
}
