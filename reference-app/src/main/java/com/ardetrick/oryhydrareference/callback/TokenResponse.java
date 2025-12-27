package com.ardetrick.oryhydrareference.callback;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;

@JsonIgnoreProperties(ignoreUnknown = true)
public record TokenResponse(
        @JsonProperty("access_token") String accessToken,
        @JsonProperty("token_type") String tokenType,
        @JsonProperty("expires_in") Long expiresIn,
        @JsonProperty("refresh_token") String refreshToken,
        @JsonProperty("id_token") String idToken,
        @JsonProperty("scope") String scope
) {
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    public static TokenResponse fromJson(String json) {
        try {
            return OBJECT_MAPPER.readValue(json, TokenResponse.class);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to parse token response: " + e.getMessage(), e);
        }
    }
}
