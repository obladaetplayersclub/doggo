package com.doggo.security;

import com.doggo.entity.UserAccount;
import com.doggo.entity.UserRole;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

public record AuthenticatedUser(
	UUID id,
	String email,
	String password,
	UserRole role,
	String displayName
) implements UserDetails {

	public static AuthenticatedUser from(UserAccount user) {
		return new AuthenticatedUser(
			user.getId(),
			user.getEmail(),
			user.getPasswordHash(),
			user.getRole(),
			user.getDisplayName()
		);
	}

	@Override
	public Collection<? extends GrantedAuthority> getAuthorities() {
		return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
	}

	@Override
	public String getPassword() {
		return password;
	}

	@Override
	public String getUsername() {
		return email;
	}
}
