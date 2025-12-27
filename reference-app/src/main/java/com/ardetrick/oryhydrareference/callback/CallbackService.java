package com.ardetrick.oryhydrareference.callback;

import lombok.AccessLevel;
import lombok.Data;
import lombok.NonNull;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import lombok.val;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CallbackService {

    @NonNull Properties properties;
    @NonNull HttpClient httpClient;

    public CallbackService(@NonNull Properties properties) {
        this.properties = properties;
        this.httpClient = HttpClient.newHttpClient();
    }

    public CallbackResult processCallback(String code, String state, String scope) {
        if (properties.getClientId() == null || properties.getClientId().isBlank()) {
            log.warn("Client ID not configured - returning code without token exchange");
            return new CallbackResult(null, "Client ID not configured. Set reference-app.oauth.client-id in application.properties");
        }

        if (properties.getClientSecret() == null || properties.getClientSecret().isBlank()) {
            log.warn("Client secret not configured - returning code without token exchange");
            return new CallbackResult(null, "Client secret not configured. Set reference-app.oauth.client-secret in application.properties");
        }

        try {
            val tokenResponse = exchangeCodeForTokens(code);
            return new CallbackResult(tokenResponse, null);
        } catch (Exception e) {
            log.error("Failed to exchange code for tokens", e);
            return new CallbackResult(null, "Token exchange failed: " + e.getMessage());
        }
    }

    private TokenResponse exchangeCodeForTokens(String code) throws IOException, InterruptedException {
        val encodedParams = Map.of(
                        "grant_type", "authorization_code",
                        "code", code,
                        "redirect_uri", properties.getRedirectUri(),
                        "client_id", properties.getClientId()
                )
                .entrySet()
                .stream()
                .map(entry -> String.join("=",
                        URLEncoder.encode(entry.getKey(), StandardCharsets.UTF_8),
                        URLEncoder.encode(entry.getValue(), StandardCharsets.UTF_8))
                )
                .collect(Collectors.joining("&"));

        val credentials = properties.getClientId() + ":" + properties.getClientSecret();
        val basicAuth = "Basic " + Base64.getEncoder().encodeToString(credentials.getBytes(StandardCharsets.UTF_8));

        val request = HttpRequest.newBuilder()
                .uri(URI.create(properties.getTokenEndpoint()))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .header("Authorization", basicAuth)
                .POST(HttpRequest.BodyPublishers.ofString(encodedParams))
                .build();

        log.info("Exchanging code for tokens at {}", properties.getTokenEndpoint());

        val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            log.error("Token exchange failed with status {}: {}", response.statusCode(), response.body());
            throw new RuntimeException("Token exchange failed with status " + response.statusCode() + ": " + response.body());
        }

        log.info("Token exchange successful");
        return TokenResponse.fromJson(response.body());
    }

    @Data
    @org.springframework.context.annotation.Configuration
    @ConfigurationProperties("reference-app.oauth")
    public static class Properties {
        String clientId;
        String clientSecret;
        String redirectUri = "http://127.0.0.1:8080/callback";
        String tokenEndpoint = "http://localhost:4444/oauth2/token";
    }

}
