# OAuth 2.0 Authorization Code Grant Flow

## Complete Technical Reference for IAM Engineers

This document provides a comprehensive explanation of the OAuth 2.0 Authorization Code Grant Flow as implemented in this reference application. It is designed to serve as both a learning resource for new IAM engineers and a technical reference for senior engineers and tech leads.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Components](#architecture-components)
3. [The Complete Flow - Step by Step](#the-complete-flow---step-by-step)
4. [Security Considerations](#security-considerations)
5. [Token Types Explained](#token-types-explained)
6. [Common Pitfalls and Best Practices](#common-pitfalls-and-best-practices)
7. [Testing the Flow](#testing-the-flow)

---

## Overview

### What is the Authorization Code Grant?

The Authorization Code Grant is the most secure OAuth 2.0 flow for server-side applications. It is designed for **confidential clients** - applications that can securely store a client secret on a backend server.

**Why is it the most secure?**

1. **The access token is never exposed to the browser** - Unlike implicit flow, tokens are exchanged server-to-server
2. **Short-lived authorization codes** - The code is single-use and expires quickly (typically 10 minutes)
3. **Client authentication** - The token exchange requires client credentials, preventing stolen codes from being useful

### When to Use This Flow

| Use Case | Recommended |
|----------|-------------|
| Traditional web applications with server-side rendering | Yes |
| Single Page Applications (SPAs) | Use with PKCE |
| Mobile applications | Use with PKCE |
| Machine-to-machine communication | Use Client Credentials flow instead |
| Microservices internal communication | Use Client Credentials flow instead |

### RFC Specifications

This implementation follows:
- **RFC 6749** - The OAuth 2.0 Authorization Framework
- **OpenID Connect Core 1.0** - Identity layer on top of OAuth 2.0

---

## Architecture Components

### System Components in This Implementation

```
+------------------+     +----------------------+     +------------------+
|                  |     |                      |     |                  |
|   User Agent     |     |   Identity Provider  |     |  Authorization   |
|   (Browser)      |     |   (This App)         |     |  Server (Hydra)  |
|                  |     |                      |     |                  |
+------------------+     +----------------------+     +------------------+
                         |                      |
                         | - LoginController    |
                         | - ConsentController  |
                         | - CallbackController |
                         |                      |
                         +----------------------+
```

### Component Responsibilities

#### 1. Authorization Server (Ory Hydra)

**Location:** `http://localhost:4444` (public) / `http://localhost:4445` (admin)

**Responsibilities:**
- Manages OAuth 2.0 client registrations
- Issues authorization codes
- Exchanges codes for tokens
- Validates tokens
- Manages token lifecycle (expiration, revocation)

**Key Endpoints:**
| Endpoint | Purpose |
|----------|---------|
| `/oauth2/auth` | Authorization endpoint - starts the flow |
| `/oauth2/token` | Token endpoint - exchanges code for tokens |
| `/.well-known/openid-configuration` | Discovery document |
| `/.well-known/jwks.json` | JSON Web Key Set for token verification |

**Source Configuration:** `reference-app/src/test/resources/volume/hydra.yml`

#### 2. Identity Provider (Login/Consent UI)

**Location:** `http://localhost:8080`

**Responsibilities:**
- Authenticates users (login)
- Obtains user consent for requested scopes
- Communicates decisions back to Authorization Server

**Key Controllers:**

| Controller | Path | Purpose |
|------------|------|---------|
| `LoginController` | `/login` | Handles user authentication |
| `ConsentController` | `/consent` | Handles scope consent |
| `CallbackController` | `/callback` | Receives authorization code and exchanges for tokens |

#### 3. OAuth 2.0 Client (Relying Party)

In this demo, the client is represented by:
- The browser initiating the flow
- The `CallbackController` receiving the authorization code
- The `CallbackService` exchanging the code for tokens

**Configuration:** `.env` file
```env
hydra_client_id=<your_client_id>
hydra_client_secret=<your_client_secret>
hydra_client_redirect_uri_0=http://127.0.0.1:8080/callback
```

---

## The Complete Flow - Step by Step

### Visual Flow Diagram

```
     User          Browser         Identity Provider      Authorization Server
       |              |                   |                        |
       |   (1) Click Login               |                         |
       |------------->|                   |                        |
       |              |                   |                        |
       |              |  (2) GET /oauth2/auth?client_id=...        |
       |              |----------------------------------------------->|
       |              |                   |                        |
       |              |  (3) 302 Redirect to /login?login_challenge=...|
       |              |<-----------------------------------------------|
       |              |                   |                        |
       |              |  (4) GET /login?login_challenge=...        |
       |              |------------------>|                        |
       |              |                   |                        |
       |              |  (5) Return Login HTML                     |
       |              |<------------------|                        |
       |              |                   |                        |
       |  (6) Display Login Form         |                         |
       |<-------------|                   |                        |
       |              |                   |                        |
       |  (7) Enter Credentials          |                         |
       |------------->|                   |                        |
       |              |                   |                        |
       |              |  (8) POST /login (credentials + challenge) |
       |              |------------------>|                        |
       |              |                   |                        |
       |              |                   |  (9) Accept Login Request
       |              |                   |----------------------->|
       |              |                   |                        |
       |              |                   |  (10) Return redirect_to
       |              |                   |<-----------------------|
       |              |                   |                        |
       |              |  (11) 302 Redirect to Authorization Server |
       |              |<------------------|                        |
       |              |                   |                        |
       |              |  (12) Follow redirect                      |
       |              |------------------------------------------->|
       |              |                   |                        |
       |              |  (13) 302 Redirect to /consent?consent_challenge=...
       |              |<-------------------------------------------|
       |              |                   |                        |
       |              |  (14) GET /consent?consent_challenge=...   |
       |              |------------------>|                        |
       |              |                   |                        |
       |              |  (15) Return Consent HTML                  |
       |              |<------------------|                        |
       |              |                   |                        |
       |  (16) Display Consent Form      |                        |
       |<-------------|                   |                        |
       |              |                   |                        |
       |  (17) Grant Consent             |                        |
       |------------->|                   |                        |
       |              |                   |                        |
       |              |  (18) POST /consent (scopes + challenge)   |
       |              |------------------>|                        |
       |              |                   |                        |
       |              |                   |  (19) Accept Consent Request
       |              |                   |----------------------->|
       |              |                   |                        |
       |              |                   |  (20) Return redirect_to
       |              |                   |<-----------------------|
       |              |                   |                        |
       |              |  (21) 302 Redirect to Authorization Server |
       |              |<------------------|                        |
       |              |                   |                        |
       |              |  (22) Follow redirect                      |
       |              |------------------------------------------->|
       |              |                   |                        |
       |              |  (23) 302 Redirect to callback?code=...    |
       |              |<-------------------------------------------|
       |              |                   |                        |
       |              |  (24) GET /callback?code=...               |
       |              |------------------>|                        |
       |              |                   |                        |
       |              |                   |  (25) POST /oauth2/token
       |              |                   |  (code + client credentials)
       |              |                   |----------------------->|
       |              |                   |                        |
       |              |                   |  (26) Return tokens    |
       |              |                   |<-----------------------|
       |              |                   |                        |
       |              |  (27) Display tokens / Set session         |
       |              |<------------------|                        |
       |              |                   |                        |
       |  (28) User is authenticated      |                        |
       |<-------------|                   |                        |
       |              |                   |                        |
     User          Browser         Identity Provider      Authorization Server
```

---

### Step 1: User Initiates Login

**What Happens:**
The user clicks a "Login" or "Sign in with..." button in the application.

**Technical Details:**
```
User Action: Click login button
Result: Browser prepares to navigate to authorization endpoint
```

**Code Location:** Demo page at `http://localhost:8080/demo`

**Learning Points:**
- The login button should construct a proper authorization URL
- Never hardcode client secrets in frontend code
- The state parameter should be generated per-request for CSRF protection

---

### Step 2: Browser Requests Authorization Endpoint

**What Happens:**
The browser makes a GET request to the Authorization Server's authorization endpoint with specific query parameters.

**Technical Details:**
```http
GET /oauth2/auth?
    response_type=code&
    client_id=23953efd-639e-4ce7-bdae-b545450f800a&
    redirect_uri=http://127.0.0.1:8080/callback&
    scope=openid%20offline&
    state=12345678901234567890
Host: localhost:4444
```

**Query Parameters Explained:**

| Parameter | Required | Description | Security Implications |
|-----------|----------|-------------|----------------------|
| `response_type` | Yes | Must be `code` for this flow | Determines which OAuth flow is used |
| `client_id` | Yes | Identifies the OAuth client | Public identifier, not secret |
| `redirect_uri` | Yes | Where to send the user after authorization | Must exactly match registered URI |
| `scope` | Yes | Permissions being requested | Principle of least privilege |
| `state` | Recommended | CSRF protection token | Prevents cross-site request forgery |

**Scope Values in This System:**

| Scope | Purpose | Token Impact |
|-------|---------|--------------|
| `openid` | Enables OpenID Connect | Returns `id_token` |
| `offline` | Request refresh token | Returns `refresh_token` |
| `offline_access` | Alternative for refresh token | Returns `refresh_token` |
| `profile` | Access to user profile claims | Adds profile claims to `id_token` |

**Learning Points:**
- **redirect_uri validation is critical** - The authorization server must validate that the redirect_uri exactly matches a pre-registered URI. This prevents authorization code interception attacks.
- **state parameter** - Should be a cryptographically random string, stored in session, and validated when the callback is received.
- **scope** - Follow the principle of least privilege. Only request scopes you actually need.

**Senior Engineer Consideration:**
In production, consider implementing:
- `nonce` parameter for replay attack prevention (required for implicit flow, recommended for code flow)
- `code_challenge` and `code_challenge_method` for PKCE (required for public clients)

---

### Step 3: Authorization Server Redirects to Login

**What Happens:**
The Authorization Server (Hydra) doesn't handle authentication itself. Instead, it redirects to the configured login URL with a `login_challenge` parameter.

**Technical Details:**
```http
HTTP/1.1 302 Found
Location: http://localhost:8080/login?login_challenge=<challenge_token>
Set-Cookie: ory_hydra_login_csrf_dev=<csrf_token>; Path=/; HttpOnly; SameSite=Lax
```

**The Login Challenge:**
- A unique, opaque token identifying this authentication request
- Contains encrypted information about the original authorization request
- Must be passed back to Hydra when accepting/rejecting the login

**Learning Points:**
- **Separation of concerns** - Hydra handles OAuth protocol, your app handles authentication
- **Challenge-based flow** - This pattern allows Hydra to remain stateless while maintaining security
- **CSRF cookies** - Hydra sets cookies to prevent cross-site attacks during the flow

**Why This Design?**
```
Traditional OAuth Server          Hydra's Design
+------------------+              +------------------+
| OAuth Server     |              | Hydra            |
| - Auth logic     |              | - OAuth protocol |
| - User database  |              | - Token issuance |
| - Login UI       |              +------------------+
| - Consent UI     |                      |
+------------------+              +------------------+
                                  | Your App         |
                                  | - Auth logic     |
                                  | - User database  |
                                  | - Login UI       |
                                  | - Consent UI     |
                                  +------------------+
```

This separation allows you to:
- Use any authentication method (password, MFA, SSO, biometrics)
- Integrate with existing user databases
- Customize the UI completely
- Implement complex authentication policies

---

### Step 4: Browser Requests Login Page

**What Happens:**
The browser follows the redirect and requests the login page from the Identity Provider.

**Technical Details:**
```http
GET /login?login_challenge=6LbJ2RkDvQufofzM1i5_mjyVE4vHfJIjX_KCBSqqv6C1lJLD8aZCbhAIcGR9xbMZ...
Host: localhost:8080
```

**Code Location:** `LoginController.java`

```java
@GetMapping
public ModelAndView loginEndpoint(@RequestParam("login_challenge") final String loginChallenge) {
    val result = loginService.processInitialLoginRequest(loginChallenge);
    return LoginModelAndViewMapper.map(result);
}
```

**What the Controller Does:**
1. Receives the login challenge from query parameter
2. Calls `LoginService.processInitialLoginRequest()`
3. The service calls Hydra Admin API to get login request details
4. Returns appropriate view (login form or redirect if skip is true)

**Learning Points:**
- **Challenge validation** - Always validate the challenge with Hydra before showing the login form
- **Skip logic** - If the user has an existing session, Hydra may indicate to skip the login UI

---

### Step 5: Identity Provider Returns Login HTML

**What Happens:**
The Identity Provider returns an HTML login form to the browser.

**Technical Details:**
```html
<!-- login.ftlh template -->
<form method="post" action="/login">
    <input type="hidden" name="loginChallenge" value="${loginChallenge}">
    <input type="email" name="loginEmail" required>
    <input type="password" name="loginPassword" required>
    <input type="submit" name="submit" value="Log in">
</form>
```

**Code Location:** `reference-app/src/main/resources/templates/login.ftlh`

**Critical Security Elements:**
1. **Hidden challenge field** - The login challenge must be submitted with the form
2. **HTTPS in production** - Never transmit credentials over HTTP
3. **CSRF token** - Should be included (handled by Spring Security)

**Learning Points:**
- **Never log passwords** - Even in debug mode
- **Rate limiting** - Implement rate limiting on login endpoints
- **Account lockout** - Consider locking accounts after failed attempts

---

### Step 6: User Sees Login Form

**What Happens:**
The browser renders the login form for the user.

**User Experience Considerations:**
- Clear error messages without revealing security information
- Password visibility toggle
- Remember me option (affects session duration)
- Links to password reset, registration

---

### Step 7: User Enters Credentials

**What Happens:**
The user enters their username/email and password.

**Security Considerations:**
- **Password managers** - Ensure form fields have proper `autocomplete` attributes
- **Phishing protection** - Users should verify they're on the correct domain
- **Credential stuffing** - Implement CAPTCHA or similar after failed attempts

---

### Step 8: Browser Submits Login Form

**What Happens:**
The browser POSTs the login form to the Identity Provider.

**Technical Details:**
```http
POST /login HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded

loginChallenge=6LbJ2RkDvQufofzM1i5_mjyVE4vHfJIjX...&
loginEmail=foo@bar.com&
loginPassword=password&
submit=Log+in
```

**Code Location:** `LoginController.java`

```java
@PostMapping
public ModelAndView submitLoginForm(final LoginForm loginForm) {
    val result = loginService.processLoginForm(loginForm);
    return LoginModelAndViewMapper.map(result);
}
```

**Learning Points:**
- **POST not GET** - Credentials should never be in URL (visible in logs, history)
- **Content-Type** - Form data uses `application/x-www-form-urlencoded`

---

### Step 9: Identity Provider Validates Credentials and Accepts Login

**What Happens:**
The Identity Provider validates the credentials and, if valid, tells Hydra to accept the login.

**Technical Details:**

**Credential Validation (simplified in this demo):**
```java
// LoginService.java
private static final String VALID_PASSWORD = "password";

private boolean isValidCredentials(LoginForm loginForm) {
    return VALID_PASSWORD.equals(loginForm.loginPassword());
}
```

**Accept Login Request to Hydra:**
```java
// HydraAdminClient.java
public OAuth2RedirectTo acceptLoginRequest(String loginChallenge, String loginEmail) {
    val acceptLoginRequest = new AcceptOAuth2LoginRequest();
    acceptLoginRequest.subject(loginEmail);  // User identifier
    return oAuth2Api.acceptOAuth2LoginRequest(loginChallenge, acceptLoginRequest);
}
```

**API Call to Hydra:**
```http
PUT /admin/oauth2/auth/requests/login/accept?login_challenge=<challenge>
Host: localhost:4445
Content-Type: application/json

{
    "subject": "foo@bar.com",
    "remember": false,
    "remember_for": 0
}
```

**Response from Hydra:**
```json
{
    "redirect_to": "http://localhost:4444/oauth2/auth?login_verifier=..."
}
```

**The Subject Field:**
- Uniquely identifies the user in your system
- Will appear in tokens as the `sub` claim
- Can be: email, UUID, username, or any unique identifier
- Should be stable (don't use values that can change)

**Learning Points:**
- **Never store plain text passwords** - Use bcrypt, Argon2, or similar
- **Subject stability** - The subject should never change for a user
- **Remember option** - Controls whether Hydra remembers this login for future requests

**Senior Engineer Consideration:**
```java
// Production credential validation should look like:
public boolean validateCredentials(String email, String password) {
    User user = userRepository.findByEmail(email)
        .orElseThrow(() -> new AuthenticationException("Invalid credentials"));
    
    // Use constant-time comparison to prevent timing attacks
    if (!passwordEncoder.matches(password, user.getPasswordHash())) {
        auditLog.logFailedLogin(email, request.getRemoteAddr());
        throw new AuthenticationException("Invalid credentials");
    }
    
    if (user.isLocked()) {
        throw new AccountLockedException("Account is locked");
    }
    
    auditLog.logSuccessfulLogin(email, request.getRemoteAddr());
    return true;
}
```

---

### Step 10: Hydra Returns Redirect URL

**What Happens:**
Hydra validates the accept request and returns a URL to redirect the user back to continue the OAuth flow.

**Technical Details:**
```json
{
    "redirect_to": "http://localhost:4444/oauth2/auth?login_verifier=<verifier>"
}
```

**The Login Verifier:**
- Cryptographic proof that login was completed
- Tied to the original authorization request
- Single-use and short-lived

---

### Step 11: Identity Provider Redirects to Authorization Server

**What Happens:**
The Identity Provider sends a redirect response to the browser.

**Technical Details:**
```http
HTTP/1.1 302 Found
Location: http://localhost:4444/oauth2/auth?login_verifier=<verifier>
```

**Code Location:** `LoginModelAndViewMapper.java`

```java
public static ModelAndView map(LoginResult loginResult) {
    return switch (loginResult) {
        case LoginResult.Accepted accepted -> 
            new ModelAndView("redirect:" + accepted.redirectTo());
        // ... other cases
    };
}
```

---

### Step 12: Browser Follows Redirect to Authorization Server

**What Happens:**
The browser automatically follows the redirect back to Hydra.

**Technical Details:**
```http
GET /oauth2/auth?login_verifier=<verifier>
Host: localhost:4444
Cookie: ory_hydra_login_csrf_dev=<csrf_token>
```

**Learning Points:**
- **Cookie validation** - Hydra validates the CSRF cookie set earlier
- **Verifier validation** - Hydra validates the login verifier

---

### Step 13: Authorization Server Redirects to Consent

**What Happens:**
After validating the login, Hydra redirects to the consent URL with a consent challenge.

**Technical Details:**
```http
HTTP/1.1 302 Found
Location: http://localhost:8080/consent?consent_challenge=<challenge>
Set-Cookie: ory_hydra_consent_csrf_dev=<csrf_token>; Path=/; HttpOnly; SameSite=Lax
```

**Why Separate Login and Consent?**

| Aspect | Login | Consent |
|--------|-------|---------|
| Purpose | Verify identity | Authorize access |
| Question | "Who are you?" | "Do you allow this app to...?" |
| Frequency | Once per session | Once per client+scope combination |
| Skip condition | Existing session | Previously granted consent |

**Learning Points:**
- **Consent is not authentication** - A user can be authenticated but deny consent
- **Granular consent** - Users should be able to grant partial scopes
- **Consent revocation** - Users should be able to revoke consent later

---

### Step 14: Browser Requests Consent Page

**What Happens:**
The browser requests the consent page from the Identity Provider.

**Technical Details:**
```http
GET /consent?consent_challenge=<challenge>
Host: localhost:8080
```

**Code Location:** `ConsentController.java`

```java
@GetMapping
public ModelAndView consentEndpoint(@RequestParam("consent_challenge") final String consentChallenge) {
    val response = consentService.processInitialConsentRequest(consentChallenge);
    return ConsentModelAndViewMapper.map(response);
}
```

**What the Controller Does:**
1. Receives consent challenge
2. Calls Hydra Admin API to get consent request details
3. Checks if consent can be skipped (previously granted)
4. Returns consent form or redirects if skipping

**Getting Consent Request Details:**
```java
// HydraAdminClient.java
public OAuth2ConsentRequest getConsentRequest(String consentChallenge) {
    return oAuth2Api.getOAuth2ConsentRequest(consentChallenge);
}
```

**Consent Request Contains:**
```json
{
    "challenge": "<consent_challenge>",
    "client": {
        "client_id": "23953efd-639e-4ce7-bdae-b545450f800a",
        "client_name": "My App"
    },
    "requested_scope": ["openid", "offline", "profile"],
    "requested_access_token_audience": [],
    "skip": false,
    "subject": "foo@bar.com"
}
```

---

### Step 15: Identity Provider Returns Consent HTML

**What Happens:**
The Identity Provider returns an HTML consent form showing what permissions are being requested.

**Technical Details:**
```html
<!-- consent.ftlh template -->
<h1>Authorize Application</h1>
<p>Application "My App" is requesting access to:</p>

<form method="post" action="/consent">
    <input type="hidden" name="consentChallenge" value="${consentChallenge}">
    
    <div>
        <input type="checkbox" name="scopes" value="openid" checked>
        <label>OpenID (verify your identity)</label>
    </div>
    <div>
        <input type="checkbox" name="scopes" value="offline" checked>
        <label>Offline Access (stay logged in)</label>
    </div>
    <div>
        <input type="checkbox" name="scopes" value="profile" checked>
        <label>Profile (access your profile information)</label>
    </div>
    
    <input type="checkbox" name="remember" checked>
    <label>Remember this decision</label>
    
    <button type="submit" name="submit" value="Allow access">Allow</button>
    <button type="submit" name="submit" value="Deny access">Deny</button>
</form>
```

**Code Location:** `reference-app/src/main/resources/templates/consent.ftlh`

**Learning Points:**
- **Scope descriptions** - Use human-readable descriptions, not technical scope names
- **Selective consent** - Allow users to uncheck scopes they don't want to grant
- **Remember option** - If checked, user won't see consent screen again for this client

---

### Step 16: User Sees Consent Form

**What Happens:**
The browser renders the consent form for the user.

**User Experience Best Practices:**
- Clearly identify the requesting application
- Explain each permission in plain language
- Show the application's logo if available
- Provide a link to the application's privacy policy
- Make it easy to deny consent

---

### Step 17: User Grants Consent

**What Happens:**
The user reviews the requested permissions and clicks "Allow" or "Deny".

**User Decision Points:**
- Which scopes to grant (can uncheck some)
- Whether to remember the decision
- Whether to allow or deny entirely

---

### Step 18: Browser Submits Consent Form

**What Happens:**
The browser POSTs the consent decision to the Identity Provider.

**Technical Details:**
```http
POST /consent HTTP/1.1
Host: localhost:8080
Content-Type: application/x-www-form-urlencoded

consentChallenge=<challenge>&
scopes=openid&
scopes=offline&
remember=true&
submit=Allow+access
```

**Code Location:** `ConsentController.java`

```java
@PostMapping
public ModelAndView submitConsentForm(final ConsentForm consentForm) {
    val consentResponse = consentService.processConsentForm(consentForm);
    return ConsentModelAndViewMapper.map(consentResponse);
}
```

---

### Step 19: Identity Provider Accepts Consent Request

**What Happens:**
The Identity Provider tells Hydra to accept (or reject) the consent request.

**Technical Details:**

**Accept Consent Request:**
```java
// ConsentService.java
public ConsentResponse processConsentForm(ConsentForm consentForm) {
    val consentChallenge = consentForm.consentChallenge();
    
    // Check if user denied
    if ("Deny access".equals(consentForm.submit())) {
        val oauth2RedirectTo = hydraAdminClient.rejectConsentRequest(consentChallenge);
        return new Rejected(oauth2RedirectTo.getRedirectTo());
    }
    
    // User accepted - build accept request
    val consentRequest = hydraAdminClient.getConsentRequest(consentChallenge);
    
    val acceptConsentRequest = AcceptConsentRequest.builder()
            .consentChallenge(consentChallenge)
            .remember(consentForm.isRemember())
            .grantAccessTokenAudience(consentRequest.getRequestedAccessTokenAudience())
            .scopes(consentForm.scopes())  // Only granted scopes
            .build();
    
    val oauth2RedirectTo = hydraAdminClient.acceptConsentRequest(acceptConsentRequest);
    return new Accepted(oauth2RedirectTo.getRedirectTo());
}
```

**API Call to Hydra:**
```http
PUT /admin/oauth2/auth/requests/consent/accept?consent_challenge=<challenge>
Host: localhost:4445
Content-Type: application/json

{
    "grant_scope": ["openid", "offline"],
    "grant_access_token_audience": [],
    "remember": true,
    "remember_for": 3600,
    "session": {
        "id_token": {
            "exampleCustomClaimKey": "example custom claim value"
        }
    }
}
```

**The Session Object:**
This is where you can add custom claims to tokens:

```java
// OryHydraRequestMapper.java
public static AcceptOAuth2ConsentRequest map(AcceptConsentRequest acceptConsentRequest) {
    val session = new AcceptOAuth2ConsentRequestSession();
    session.idToken(Map.of(
        "exampleCustomClaimKey", "example custom claim value"
    ));
    
    return new AcceptOAuth2ConsentRequest()
            .grantScope(acceptConsentRequest.scopes())
            .grantAccessTokenAudience(acceptConsentRequest.grantAccessTokenAudience())
            .remember(acceptConsentRequest.remember())
            .session(session);
}
```

**Learning Points:**
- **Partial scope grants** - Only include scopes the user actually approved
- **Custom claims** - Add application-specific data to tokens via session
- **Remember duration** - Control how long the consent decision is cached

**Senior Engineer Consideration:**
Custom claims in tokens should be:
- Minimal (tokens travel with every request)
- Non-sensitive (tokens can be decoded by anyone)
- Stable (avoid frequently changing values)

---

### Step 20: Hydra Returns Redirect URL

**What Happens:**
Hydra validates the consent acceptance and returns a URL to continue the flow.

**Technical Details:**
```json
{
    "redirect_to": "http://localhost:4444/oauth2/auth?consent_verifier=<verifier>"
}
```

---

### Step 21: Identity Provider Redirects to Authorization Server

**What Happens:**
The Identity Provider redirects the browser back to Hydra.

**Technical Details:**
```http
HTTP/1.1 302 Found
Location: http://localhost:4444/oauth2/auth?consent_verifier=<verifier>
```

---

### Step 22: Browser Follows Redirect

**What Happens:**
The browser follows the redirect to Hydra.

**Technical Details:**
```http
GET /oauth2/auth?consent_verifier=<verifier>
Host: localhost:4444
Cookie: ory_hydra_consent_csrf_dev=<csrf_token>
```

---

### Step 23: Authorization Server Redirects with Authorization Code

**What Happens:**
Hydra generates an authorization code and redirects to the client's callback URL.

**Technical Details:**
```http
HTTP/1.1 302 Found
Location: http://127.0.0.1:8080/callback?
    code=ory_ac_gU89agJF5BA5jv3FONn93xJ5HVHomE8Ui_6EcZO7kjA...&
    scope=offline_access+openid+offline+profile&
    state=12345678901234567890
```

**The Authorization Code:**
- Opaque string (implementation-specific format)
- Single-use (can only be exchanged once)
- Short-lived (typically 10 minutes)
- Bound to: client_id, redirect_uri, scope, subject

**Learning Points:**
- **State validation** - The client MUST validate that the returned state matches what was sent
- **Code security** - The code is useless without the client secret
- **Scope confirmation** - The returned scope may differ from requested (if user denied some)

---

### Step 24: Browser Requests Callback Endpoint

**What Happens:**
The browser requests the callback URL on the client application.

**Technical Details:**
```http
GET /callback?code=ory_ac_gU89agJF5BA5jv3FONn93xJ5HVHomE8Ui...&scope=offline_access+openid&state=12345678901234567890
Host: 127.0.0.1:8080
```

**Code Location:** `CallbackController.java`

```java
@GetMapping
public ModelAndView handleCallback(
        @RequestParam(value = "code", required = false) String code,
        @RequestParam(value = "state", required = false) String state,
        @RequestParam(value = "scope", required = false) String scope,
        @RequestParam(value = "error", required = false) String error,
        @RequestParam(value = "error_description", required = false) String errorDescription
) {
    log.info("Callback received - code: {}, state: {}, scope: {}", 
            code != null ? "present" : "null", state, scope);

    if (error != null) {
        return new ModelAndView("callback-error")
                .addObject("error", error)
                .addObject("errorDescription", errorDescription);
    }

    val callbackResult = callbackService.processCallback(code, state, scope);
    return new ModelAndView("callback")
            .addObject("code", code)
            .addObject("tokenResponse", callbackResult.tokenResponse())
            .addObject("error", callbackResult.error());
}
```

**Error Handling:**
The callback may receive an error instead of a code:
```
/callback?error=access_denied&error_description=The+resource+owner+denied+the+request
```

**Common Error Codes:**

| Error | Meaning |
|-------|---------|
| `access_denied` | User denied consent |
| `invalid_request` | Missing or invalid parameters |
| `unauthorized_client` | Client not authorized for this grant type |
| `invalid_scope` | Requested scope is invalid |
| `server_error` | Authorization server error |

---

### Step 25: Client Exchanges Code for Tokens

**What Happens:**
The client (server-side) makes a POST request to the token endpoint to exchange the authorization code for tokens.

**Technical Details:**
```http
POST /oauth2/token HTTP/1.1
Host: localhost:4444
Content-Type: application/x-www-form-urlencoded
Authorization: Basic base64(client_id:client_secret)

grant_type=authorization_code&
code=ory_ac_gU89agJF5BA5jv3FONn93xJ5HVHomE8Ui...&
redirect_uri=http://127.0.0.1:8080/callback&
client_id=23953efd-639e-4ce7-bdae-b545450f800a
```

**Code Location:** `CallbackService.java`

```java
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

    val response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
    
    if (response.statusCode() != 200) {
        throw new RuntimeException("Token exchange failed: " + response.body());
    }

    return TokenResponse.fromJson(response.body());
}
```

**Client Authentication Methods:**

| Method | Description | Security Level |
|--------|-------------|----------------|
| `client_secret_basic` | Base64 encoded in Authorization header | Standard |
| `client_secret_post` | In request body | Lower (visible in logs) |
| `private_key_jwt` | Signed JWT assertion | Higher |
| `none` | No authentication (public clients) | Requires PKCE |

**Learning Points:**
- **Server-to-server** - This request is made from your backend, not the browser
- **Client secret** - Never expose this in frontend code or logs
- **redirect_uri must match** - Must exactly match the one used in authorization request

**Senior Engineer Consideration:**
```java
// Production code should:
// 1. Use connection pooling
// 2. Implement retry with exponential backoff
// 3. Set appropriate timeouts
// 4. Handle network errors gracefully

HttpClient httpClient = HttpClient.newBuilder()
    .connectTimeout(Duration.ofSeconds(10))
    .build();
```

---

### Step 26: Authorization Server Returns Tokens

**What Happens:**
Hydra validates the code and client credentials, then returns the tokens.

**Technical Details:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
    "access_token": "ory_at_...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "refresh_token": "ory_rt_...",
    "scope": "offline_access openid offline profile",
    "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Code Location:** `TokenResponse.java`

```java
@JsonIgnoreProperties(ignoreUnknown = true)
public record TokenResponse(
        @JsonProperty("access_token") String accessToken,
        @JsonProperty("token_type") String tokenType,
        @JsonProperty("expires_in") Long expiresIn,
        @JsonProperty("refresh_token") String refreshToken,
        @JsonProperty("id_token") String idToken,
        @JsonProperty("scope") String scope
) {
    public static TokenResponse fromJson(String json) {
        return new ObjectMapper().readValue(json, TokenResponse.class);
    }
}
```

**Validation Hydra Performs:**
1. Code is valid and not expired
2. Code has not been used before
3. Client credentials are correct
4. redirect_uri matches the original request
5. Client is authorized for the requested grant type

---

### Step 27: Client Processes Token Response

**What Happens:**
The client receives and processes the tokens.

**Technical Details:**

**What to do with each token:**

| Token | Storage | Usage |
|-------|---------|-------|
| `access_token` | Memory or secure session | Include in API requests |
| `refresh_token` | Secure, encrypted storage | Get new access tokens |
| `id_token` | Can be stored or discarded after validation | Verify user identity |

**ID Token Validation (Critical):**
```java
// The id_token is a JWT that MUST be validated:
// 1. Verify signature using Hydra's public keys (JWKS)
// 2. Verify issuer (iss) matches expected value
// 3. Verify audience (aud) contains your client_id
// 4. Verify expiration (exp) is in the future
// 5. Verify issued at (iat) is reasonable
// 6. If nonce was sent, verify it matches

DecodedJWT jwt = JWT.decode(idToken);

// Verify signature
JwkProvider provider = new UrlJwkProvider("http://localhost:4444/.well-known/jwks.json");
Jwk jwk = provider.get(jwt.getKeyId());
Algorithm algorithm = Algorithm.RSA256((RSAPublicKey) jwk.getPublicKey(), null);
algorithm.verify(jwt);

// Verify claims
assert jwt.getIssuer().equals("http://localhost:4444");
assert jwt.getAudience().contains(clientId);
assert jwt.getExpiresAt().after(new Date());
```

**Learning Points:**
- **Never trust tokens without validation** - Always verify signatures and claims
- **Token storage security** - Access tokens in memory, refresh tokens encrypted at rest
- **Token rotation** - Use refresh tokens to get new access tokens before expiry

---

### Step 28: User is Authenticated

**What Happens:**
The user is now authenticated and the client has tokens to access protected resources.

**What Happens Next:**
1. Client creates a session for the user
2. Access token is used to call protected APIs
3. When access token expires, refresh token is used to get a new one
4. User can access protected resources until they log out

**Using the Access Token:**
```http
GET /api/protected-resource HTTP/1.1
Host: api.example.com
Authorization: Bearer ory_at_...
```

**Refreshing Tokens:**
```http
POST /oauth2/token HTTP/1.1
Host: localhost:4444
Content-Type: application/x-www-form-urlencoded
Authorization: Basic base64(client_id:client_secret)

grant_type=refresh_token&
refresh_token=ory_rt_...
```

---

## Security Considerations

### CSRF Protection

**State Parameter:**
```java
// Generate state before authorization request
String state = generateSecureRandom(32);
session.setAttribute("oauth_state", state);

// Validate state in callback
String returnedState = request.getParameter("state");
String expectedState = session.getAttribute("oauth_state");
if (!constantTimeEquals(returnedState, expectedState)) {
    throw new SecurityException("State mismatch - possible CSRF attack");
}
```

### Token Security

| Token Type | Threat | Mitigation |
|------------|--------|------------|
| Access Token | Theft | Short expiry, HTTPS only, don't log |
| Refresh Token | Theft | Encrypted storage, rotation, binding |
| ID Token | Tampering | Signature verification |
| Auth Code | Interception | PKCE, short expiry, single-use |

### PKCE (Proof Key for Code Exchange)

For public clients (SPAs, mobile apps), add PKCE:

```java
// Before authorization request
String codeVerifier = generateSecureRandom(64);
String codeChallenge = base64UrlEncode(sha256(codeVerifier));

// Authorization request includes:
// code_challenge=<codeChallenge>
// code_challenge_method=S256

// Token request includes:
// code_verifier=<codeVerifier>
```

---

## Token Types Explained

### Access Token

**Purpose:** Authorize API requests

**Format:** Opaque string or JWT (implementation-dependent)

**Lifetime:** Short (typically 1 hour)

**Claims (if JWT):**
```json
{
    "iss": "http://localhost:4444",
    "sub": "foo@bar.com",
    "aud": ["https://api.example.com"],
    "exp": 1703612400,
    "iat": 1703608800,
    "scope": "openid offline profile",
    "client_id": "23953efd-639e-4ce7-bdae-b545450f800a"
}
```

### Refresh Token

**Purpose:** Obtain new access tokens without user interaction

**Format:** Opaque string

**Lifetime:** Longer (hours to days, configurable)

**Security:**
- Should be stored securely (encrypted)
- Can be rotated on each use
- Can be revoked

### ID Token

**Purpose:** Prove user identity (OpenID Connect)

**Format:** Always JWT

**Standard Claims:**
```json
{
    "iss": "http://localhost:4444",
    "sub": "foo@bar.com",
    "aud": "23953efd-639e-4ce7-bdae-b545450f800a",
    "exp": 1703612400,
    "iat": 1703608800,
    "auth_time": 1703608800,
    "nonce": "abc123",
    "exampleCustomClaimKey": "example custom claim value"
}
```

---

## Common Pitfalls and Best Practices

### Pitfall 1: Storing Tokens Insecurely

**Wrong:**
```javascript
// Never store tokens in localStorage (XSS vulnerable)
localStorage.setItem('access_token', token);
```

**Right:**
```java
// Store in HTTP-only, secure cookies or server-side session
response.addCookie(new Cookie("session_id", sessionId) {{
    setHttpOnly(true);
    setSecure(true);
    setSameSite("Strict");
}});
```

### Pitfall 2: Not Validating redirect_uri

**Wrong:**
```java
// Accepting any redirect_uri
String redirectUri = request.getParameter("redirect_uri");
return "redirect:" + redirectUri;
```

**Right:**
```java
// Validate against registered URIs
if (!registeredRedirectUris.contains(redirectUri)) {
    throw new InvalidRequestException("Invalid redirect_uri");
}
```

### Pitfall 3: Logging Sensitive Data

**Wrong:**
```java
log.info("Token exchange: code={}, secret={}", code, clientSecret);
```

**Right:**
```java
log.info("Token exchange: code={}, client_id={}", 
    code.substring(0, 10) + "...", clientId);
```

### Pitfall 4: Not Using HTTPS

**All OAuth endpoints must use HTTPS in production:**
- Authorization endpoint
- Token endpoint
- Redirect URIs
- API endpoints using tokens

### Pitfall 5: Long-Lived Access Tokens

**Wrong:**
```yaml
access_token_lifespan: 30d
```

**Right:**
```yaml
access_token_lifespan: 1h
refresh_token_lifespan: 7d
```

---

## Testing the Flow

### Manual Testing

1. **Start the services:**
   ```bash
   docker-compose -f ./reference-app/src/test/resources/docker-compose.yml up -d
   ./gradlew bootRun
   ```

2. **Create a client (if needed):**
   ```bash
   docker-compose -f ./reference-app/src/test/resources/docker-compose.yml exec hydra \
     hydra create client \
     --endpoint http://127.0.0.1:4445 \
     --grant-type authorization_code,refresh_token \
     --response-type code,id_token \
     --scope openid --scope offline \
     --redirect-uri http://127.0.0.1:8080/callback
   ```

3. **Open the demo page:**
   ```
   http://localhost:8080/demo
   ```

4. **Follow the OAuth flow:**
   - Click the authorization link
   - Login with `foo@bar.com` / `password`
   - Grant consent
   - View tokens on callback page

### Automated Testing

See `OryHydraReferenceApplicationFunctionalTests.java` for Playwright-based end-to-end tests.

---

## Conclusion

This reference implementation provides a complete, working example of the OAuth 2.0 Authorization Code Grant Flow. Key takeaways:

1. **Separation of concerns** - Authorization server (Hydra) handles OAuth protocol, your app handles authentication and consent UI
2. **Challenge-based flow** - Login and consent challenges maintain security while allowing customization
3. **Token security** - Access tokens are short-lived, refresh tokens enable long sessions
4. **Validation is critical** - Always validate state, tokens, and redirect URIs

For production deployments, ensure you:
- Use HTTPS everywhere
- Implement proper credential storage (bcrypt/Argon2)
- Add rate limiting and account lockout
- Implement PKCE for public clients
- Set up proper token lifetimes
- Enable audit logging

---

## References

- [RFC 6749 - OAuth 2.0](https://tools.ietf.org/html/rfc6749)
- [RFC 7636 - PKCE](https://tools.ietf.org/html/rfc7636)
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [Ory Hydra Documentation](https://www.ory.sh/docs/hydra)
- [OAuth 2.0 Security Best Practices](https://tools.ietf.org/html/draft-ietf-oauth-security-topics)
