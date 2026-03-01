package com.doggo.repository;

import com.doggo.entity.UserAccount;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserAccountRepository extends JpaRepository<UserAccount, UUID> {

	Optional<UserAccount> findByEmailIgnoreCase(String email);

	boolean existsByEmailIgnoreCase(String email);
}
