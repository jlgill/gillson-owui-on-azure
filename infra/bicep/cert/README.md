# Certificate Directory

This directory contains certificates required for the deployment.

## Required File

### `cloudflare-origin-ca.cer`

Before deploying `main.bicep`, you **MUST** place your Cloudflare Origin CA certificate file here with the exact filename `cloudflare-origin-ca.cer`.

This certificate is used by Application Gateway to establish trust with Cloudflare's proxy when using Cloudflare as a CDN/WAF in front of your Azure infrastructure.

## How to Obtain the Certificate

1. Log in to your [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **SSL/TLS** → **Origin Server**
3. Click **Create Certificate**
4. Select **RSA (2048)** as the private key type
5. Add your domain (e.g., `openwebui.example.com` and `*.example.com`)
6. Choose certificate validity (recommended: 15 years for Origin CA certificates)
7. Click **Create**
8. Download the **Origin Certificate** (the PEM format)
9. Save it to this directory as `cloudflare-origin-ca.cer`

## Important Notes

- **Do NOT commit** the actual certificate file to source control
- The `.cer` file should be in PEM format (Base64-encoded)
- The deployment will fail if this file is missing or incorrectly formatted
- Keep your private key secure and never commit it to source control

## Security Reminder

Consider adding `*.cer` and `*.pem` to your `.gitignore` file to prevent accidental commits:

```gitignore
# Certificates
infra/bicep/cert/*.cer
infra/bicep/cert/*.pem
infra/bicep/cert/*.pfx
```
