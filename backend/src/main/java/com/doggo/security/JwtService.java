package com.doggo.security;

import com.doggo.config.SecurityProperties;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

	private final SecurityProperties properties;
	private final SecretKey signingKey;

	public JwtService(SecurityProperties properties) {
		this.properties = properties;
		this.signingKey = Keys.hmacShaKeyFor(resolveSecret(properties.jwtSecret()));
	}

	public String generateToken(AuthenticatedUser user) {
		Instant now = Instant.now();
		return Jwts.builder()
			.subject(user.getUsername())
			.issuer(properties.jwtIssuer())
			.issuedAt(Date.from(now))
			.expiration(Date.from(now.plus(properties.jwtExpiration())))
			.claim("uid", user.id().toString())
			.claim("role", user.role().name())
			.signWith(signingKey)
			.compact();
	}

	public String extractUsername(String token) {
		return parseClaims(token).getSubject();
	}

	public UUID extractUserId(String token) {
		return UUID.fromString(parseClaims(token).get("uid", String.class));
	}

	public boolean isTokenValid(String token, AuthenticatedUser user) {
		Claims claims = parseClaims(token);
		return claims.getSubject().equalsIgnoreCase(user.getUsername())
			&& claims.getExpiration().after(new Date());
	}

	private Claims parseClaims(String token) {
		return Jwts.parser()
			.verifyWith(signingKey)
			.requireIssuer(properties.jwtIssuer())
			.build()
			.parseSignedClaims(token)
			.getPayload();
	}

	private byte[] resolveSecret(String rawSecret) {
		if (rawSecret.startsWith("base64:")) {
			return Decoders.BASE64.decode(rawSecret.substring("base64:".length()));
		}
		return rawSecret.getBytes();
	}
}
