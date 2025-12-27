<!DOCTYPE html>
<html>
<head>
    <title>OAuth2 Callback - Error</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            max-width: 600px;
            margin: 40px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        h1 {
            color: #c62828;
        }
        .error-box {
            background-color: #ffebee;
            border: 1px solid #f44336;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .error-code {
            font-family: monospace;
            background-color: #fff;
            padding: 5px 10px;
            border-radius: 4px;
            display: inline-block;
        }
        .section {
            background-color: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        a {
            color: #1976d2;
        }
    </style>
</head>
<body>
    <h1>OAuth2 Error</h1>

    <div class="error-box">
        <p><strong>Error:</strong> <span class="error-code">${error!''}</span></p>
        <#if errorDescription??>
            <p><strong>Description:</strong> ${errorDescription}</p>
        </#if>
    </div>

    <div class="section">
        <h2>What happened?</h2>
        <p>The OAuth2 authorization flow encountered an error. This could be due to:</p>
        <ul>
            <li>User denied the consent request</li>
            <li>Invalid or expired authorization request</li>
            <li>Misconfigured OAuth2 client</li>
        </ul>
    </div>

    <div class="section">
        <h2>Next Steps</h2>
        <ul>
            <li><a href="/demo">Return to Demo Page and try again</a></li>
        </ul>
    </div>
</body>
</html>
