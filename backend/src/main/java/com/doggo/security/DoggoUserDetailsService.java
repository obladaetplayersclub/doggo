package com.doggo.security;

import com.doggo.repository.UserAccountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DoggoUserDetailsService implements UserDetailsService {

	private final UserAccountRepository userAccountRepository;

	@Override
	public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
		return userAccountRepository.findByEmailIgnoreCase(username)
			.map(AuthenticatedUser::from)
			.orElseThrow(() -> new UsernameNotFoundException("User not found"));
	}
}
