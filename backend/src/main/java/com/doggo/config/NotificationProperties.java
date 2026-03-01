package com.doggo.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app.notifications")
public record NotificationProperties(boolean enabled) {
}
