# OAuth2 Client Guide

Complete guide to creating OAuth2 clients and obtaining tokens with Ory Hydra.

## Prerequisites

1. **Docker** and **Docker Compose** installed
2. **Hydra running** via docker-compose:
   ```bash
   docker-compose -f ./reference-app/src/test/resources/docker-compose.yml up -d
   ```
3. **Application running** (for login/consent UI):
   ```bash
   ./gradlew bootRun
   ```

## Quick Start

### Step 1: Create an OAuth2 Client

```bash
docker-compose -f ./reference-app/src/test/resources/docker-compose.yml exec hydra \
  hydra create client \
  --endpoint http://127.0.0.1:4445 \
  --grant-type authorization_code,refresh_token \
  --response-type code,id_token \
  --format json \
  --scope openid --scope offline \
  --redirect-uri http://127.0.0.1:5555/callback
```

**Output:**
```json
{
  "client_id": "88544ccf-e620-4260-b5ca-9fc11a743eb0",
  "client_secret": "mb7R-Vi_Z5XvE.4v.txajTMKBt",
  ...
}
```

> ⚠️ **Save the `client_id` and `client_secret`** — the secret won't be shown again!

### Step 2: Update Environment Variables

Edit `.env` with your new credentials:
```env
hydra_client_id=YOUR_CLIENT_ID
hydra_client_secret=YOUR_CLIENT_SECRET
hydra_client_redirect_uri_0=http://127.0.0.1:5555/callback

HYDRA_ADMIN_URL=http://localhost:4445
HYDRA_PUBLIC_URL=http://localhost:4444
```

### Step 3: Start the OAuth Flow

Open this URL in your browser (replace `YOUR_CLIENT_ID`):

```
http://localhost:4444/oauth2/auth?client_id=YOUR_CLIENT_ID&response_type=code&scope=openid%20offline&redirect_uri=http://127.0.0.1:5555/callback&state=random123
```

**What happens:**
1. Hydra redirects to login page (`http://localhost:8080/login`)
2. Enter credentials: `foo@bar.com` / `password`
3. Hydra redirects to consent page (`http://localhost:8080/consent`)
4. Click "Allow Access"
5. Hydra redirects to callback URL with authorization code

### Step 4: Extract the Authorization Code

After consent, you'll be redirected to:
```
http://127.0.0.1:5555/callback?code=ory_ac_XXXXX&scope=openid+offline&state=random123
```

The `code` parameter is your **authorization code**. Copy it.

> Note: The "site can't be reached" error is expected — nothing is listening on port 5555. Just copy the code from the URL.

### Step 5: Exchange Code for Tokens

```bash
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "grant_type=authorization_code" \
  -d "code=YOUR_AUTHORIZATION_CODE" \
  -d "redirect_uri=http://127.0.0.1:5555/callback" | jq
```

**Response:**
```json
{
  "access_token": "ory_at_...",
  "expires_in": 3600,
  "id_token": "eyJhbGciOiJSUzI1NiIs...",
  "refresh_token": "ory_rt_...",
  "scope": "openid offline",
  "token_type": "bearer"
}
```

---

## Token Types Explained

| Token | Purpose | Lifetime |
|-------|---------|----------|
| **access_token** | Authorize API requests | 1 hour |
| **id_token** | User identity (JWT) | 1 hour |
| **refresh_token** | Get new access tokens | 1 hour (configurable) |

---

## Common Operations

### List All Clients

```bash
curl http://localhost:4445/admin/clients | jq
```

### Get Specific Client

```bash
curl http://localhost:4445/admin/clients/YOUR_CLIENT_ID | jq
```

### Delete a Client

```bash
curl -X DELETE http://localhost:4445/admin/clients/YOUR_CLIENT_ID
```

### Refresh Access Token

```bash
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "grant_type=refresh_token" \
  -d "refresh_token=YOUR_REFRESH_TOKEN" | jq
```

### Introspect Token (Validate)

```bash
curl -X POST http://localhost:4445/admin/oauth2/introspect \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "token=YOUR_ACCESS_TOKEN" | jq
```

### Revoke Token

```bash
curl -X POST http://localhost:4444/oauth2/revoke \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "token=YOUR_TOKEN"
```

---

## Create Client with Custom Settings

### With Specific Client ID and Secret

```bash
docker-compose -f ./reference-app/src/test/resources/docker-compose.yml exec hydra \
  hydra create client \
  --endpoint http://127.0.0.1:4445 \
  --id my-custom-client \
  --secret my-custom-secret \
  --grant-type authorization_code,refresh_token \
  --response-type code,id_token \
  --scope openid --scope offline \
  --redirect-uri http://127.0.0.1:5555/callback
```

### Client Credentials Grant (Machine-to-Machine)

```bash
docker-compose -f ./reference-app/src/test/resources/docker-compose.yml exec hydra \
  hydra create client \
  --endpoint http://127.0.0.1:4445 \
  --grant-type client_credentials \
  --scope openid \
  --format json
```

Get token:
```bash
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "CLIENT_ID:CLIENT_SECRET" \
  -d "grant_type=client_credentials" \
  -d "scope=openid" | jq
```

---

## Decode ID Token (JWT)

The `id_token` is a JWT. Decode it at [jwt.io](https://jwt.io) or:

```bash
echo "YOUR_ID_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null | jq
```

**Payload contains:**
```json
{
  "sub": "foo@bar.com",
  "aud": ["your-client-id"],
  "exp": 1703608800,
  "iat": 1703605200,
  "iss": "http://localhost:4444"
}
```

---

## Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Hydra Public | http://localhost:4444 | OAuth endpoints |
| Hydra Admin | http://localhost:4445 | Client management |
| Application | http://localhost:8080 | Login/Consent UI |
| Demo Page | http://localhost:8080/demo | Interactive demo |

---

## Troubleshooting

### "invalid_client" Error
- Verify `client_id` and `client_secret` are correct
- Check client exists: `curl http://localhost:4445/admin/clients | jq`

### "invalid_grant" Error
- Authorization code expired (use within 10 minutes)
- Code already used (codes are single-use)
- Redirect URI mismatch

### "Connection Refused" on Callback
- Expected behavior — no app listening on port 5555
- Just copy the `code` from the URL bar

### Hydra Not Running
```bash
docker-compose -f ./reference-app/src/test/resources/docker-compose.yml up -d
curl http://localhost:4444/health/ready  # Should return {"status":"ok"}
```

---

## Complete Example

```bash
# 1. Start services
docker-compose -f ./reference-app/src/test/resources/docker-compose.yml up -d
./gradlew bootRun &

# 2. Create client
CLIENT_JSON=$(docker-compose -f ./reference-app/src/test/resources/docker-compose.yml exec -T hydra \
  hydra create client \
  --endpoint http://127.0.0.1:4445 \
  --grant-type authorization_code,refresh_token \
  --response-type code,id_token \
  --format json \
  --scope openid --scope offline \
  --redirect-uri http://127.0.0.1:5555/callback)

CLIENT_ID=$(echo $CLIENT_JSON | jq -r '.client_id')
CLIENT_SECRET=$(echo $CLIENT_JSON | jq -r '.client_secret')

echo "Client ID: $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"

# 3. Open browser for authorization
echo "Open this URL in browser:"
echo "http://localhost:4444/oauth2/auth?client_id=${CLIENT_ID}&response_type=code&scope=openid%20offline&redirect_uri=http://127.0.0.1:5555/callback&state=random123"

# 4. After login/consent, exchange code (replace YOUR_CODE)
# curl -X POST http://localhost:4444/oauth2/token \
#   -u "${CLIENT_ID}:${CLIENT_SECRET}" \
#   -d "grant_type=authorization_code" \
#   -d "code=YOUR_CODE" \
#   -d "redirect_uri=http://127.0.0.1:5555/callback" | jq
```
