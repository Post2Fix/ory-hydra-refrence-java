<!DOCTYPE html>
<html>
<head>
    <title>OAuth2 Callback - Token Received</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            max-width: 900px;
            margin: 40px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #2e7d32;
        }
        .success-banner {
            background-color: #e8f5e9;
            border: 1px solid #4caf50;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .error-banner {
            background-color: #ffebee;
            border: 1px solid #f44336;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .section {
            background-color: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .section h2 {
            margin-top: 0;
            color: #333;
            border-bottom: 2px solid #2196f3;
            padding-bottom: 10px;
        }
        .token-display {
            background-color: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            padding: 15px;
            word-break: break-all;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            max-height: 150px;
            overflow-y: auto;
        }
        .label {
            font-weight: bold;
            color: #555;
            margin-bottom: 5px;
        }
        .value {
            margin-bottom: 15px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            text-align: left;
            padding: 10px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
        }
        .copy-btn {
            background-color: #2196f3;
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            margin-left: 10px;
        }
        .copy-btn:hover {
            background-color: #1976d2;
        }
    </style>
</head>
<body>
    <h1>OAuth2 Callback Received</h1>

    <#if error??>
        <div class="error-banner">
            <strong>Note:</strong> ${error}
            <p>The authorization code was received but automatic token exchange failed. You can manually exchange the code using curl.</p>
        </div>
    <#else>
        <div class="success-banner">
            <strong>Success!</strong> Authorization code received and tokens obtained successfully.
        </div>
    </#if>

    <div class="section">
        <h2>Authorization Response</h2>
        <table>
            <tr>
                <th>Parameter</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Authorization Code</td>
                <td><code>${code!''}</code></td>
            </tr>
            <tr>
                <td>State</td>
                <td><code>${state!''}</code></td>
            </tr>
            <tr>
                <td>Scope</td>
                <td><code>${scope!''}</code></td>
            </tr>
        </table>
    </div>

    <#if tokenResponse??>
        <div class="section">
            <h2>Token Response</h2>
            
            <div class="label">Access Token:</div>
            <div class="token-display" id="access-token">${tokenResponse.accessToken()!''}</div>
            <button class="copy-btn" onclick="copyToClipboard('access-token')">Copy</button>
            
            <br/><br/>
            
            <div class="label">Token Type:</div>
            <div class="value">${tokenResponse.tokenType()!''}</div>
            
            <div class="label">Expires In:</div>
            <div class="value">${tokenResponse.expiresIn()!''} seconds</div>
            
            <div class="label">Scope:</div>
            <div class="value">${tokenResponse.scope()!''}</div>
            
            <#if tokenResponse.refreshToken()??>
                <div class="label">Refresh Token:</div>
                <div class="token-display" id="refresh-token">${tokenResponse.refreshToken()}</div>
                <button class="copy-btn" onclick="copyToClipboard('refresh-token')">Copy</button>
                <br/><br/>
            </#if>
            
            <#if tokenResponse.idToken()??>
                <div class="label">ID Token (JWT):</div>
                <div class="token-display" id="id-token">${tokenResponse.idToken()}</div>
                <button class="copy-btn" onclick="copyToClipboard('id-token')">Copy</button>
                <p><small>Decode at <a href="https://jwt.io" target="_blank">jwt.io</a></small></p>
            </#if>
        </div>
    <#else>
        <div class="section">
            <h2>Manual Token Exchange</h2>
            <p>Use this curl command to exchange the authorization code for tokens:</p>
            <div class="token-display">
curl -X POST http://localhost:4444/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "YOUR_CLIENT_ID:YOUR_CLIENT_SECRET" \
  -d "grant_type=authorization_code" \
  -d "code=${code!''}" \
  -d "redirect_uri=http://127.0.0.1:8080/callback" | jq
            </div>
        </div>
    </#if>

    <div class="section">
        <h2>Next Steps</h2>
        <ul>
            <li><a href="/demo">Return to Demo Page</a></li>
            <li><a href="https://jwt.io" target="_blank">Decode ID Token at jwt.io</a></li>
        </ul>
    </div>

    <script>
        function copyToClipboard(elementId) {
            const text = document.getElementById(elementId).innerText;
            navigator.clipboard.writeText(text).then(() => {
                alert('Copied to clipboard!');
            });
        }
    </script>
</body>
</html>
