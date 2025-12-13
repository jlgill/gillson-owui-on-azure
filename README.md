# Azure Open WebUI Quickstart

Deploy [Open WebUI](https://github.com/open-webui/open-webui) on Azure Container Apps with Entra ID authentication, Azure AI Foundry integration, and Application Gateway.

## Architecture

```
User → Cloudflare (DNS/SSL) → Application Gateway → Container App (EasyAuth) → Open WebUI
                                                                                    ↓
                                                                            Azure AI Foundry (GPT-4o)
```

## Features

- **Open WebUI** on Azure Container Apps with Entra ID authentication
- **Azure AI Foundry** with GPT models using Managed Identity
- **Application Gateway** with custom domain and SSL
- **Infrastructure as Code** using Bicep with Azure Verified Modules

## Prerequisites

- Azure subscription with Azure CLI and Bicep installed
- Custom domain with DNS provider (Cloudflare used in examples)
- SSL certificate (Cloudflare Origin Certificate for Full strict SSL mode)

## Deployment

### 1. Deploy Hub Infrastructure (APIM, Application Gateway)

```bash
az deployment sub create \
  --location uksouth \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.bicepparam
```

**Configure Cloudflare DNS:**
- Add A record pointing to Application Gateway public IP
- Enable proxy (orange cloud)
- Set SSL/TLS mode to **Full (strict)**

### 2. Deploy App Infrastructure (Container App, AI Foundry)

```bash
az deployment sub create \
  --location uksouth \
  --template-file infra/bicep/app.bicep \
  --parameters infra/bicep/app.bicepparam
```

**Grant Admin Consent (one-time):**
1. Azure Portal → **Entra ID** → **App registrations** → **app-open-webui**
2. **API permissions** → **Grant admin consent**

**Redeploy Hub to configure EasyAuth:**
```bash
az deployment sub create \
  --location uksouth \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.bicepparam
```

### 3. Import OpenAPI Spec to APIM

> **Note:** This step is required due to Bicep's character limit on inline content. The OpenAPI spec must be imported manually via Azure CLI.

```bash
az apim api import \
  --resource-group rg-lb-core \
  --service-name apim-open-webui \
  --api-id openai \
  --path "openai/v1" \
  --specification-format OpenApiJson \
  --specification-path infra/bicep/openapi/openai.openapi.json \
  --display-name "Azure OpenAI v1 API" \
  --protocols https \
  --subscription-required true
```


## Configuration

### Connect Open WebUI to Azure OpenAI

1. Navigate to Open WebUI and log in with Entra ID
2. Go to **Admin Settings** → **Connections**
3. Add OpenAI connection:
   - **API Base URL**: `https://apim-open-webui.azure-api.net/openai/v1`
   - **API Key**: Get from APIM subscription (see below)
   - **API Type**: `OpenAI`

**Get APIM Subscription Key:**
```bash
# Azure Portal: APIM → Subscriptions → Built-in all-access → Show keys
# Or via CLI:
az rest --method post \
  --url "/subscriptions/<sub-id>/resourceGroups/rg-lb-core/providers/Microsoft.ApiManagement/service/apim-open-webui/subscriptions/master/listSecrets?api-version=2024-05-01" \
  --query "primaryKey" -o tsv
```

> **Note:** Foundry doesn't support `/models` endpoint. Manually add models in **Admin Settings** → **Models** (e.g., `gpt-4o`, `gpt-4o-mini`).

### Allow APIM Access to Foundry (if using network ACLs)

```bash
# Get APIM public IPs and add to Foundry firewall rules
az apim show \
  --resource-group rg-lb-core \
  --name apim-open-webui \
  --query publicIpAddresses -o tsv
```

## Architecture Notes

**Scale to Zero:**
- Container App scales to zero after inactivity (cold start: 10-30s)
- Set `minReplicas: 1` in [app.bicep](infra/bicep/app.bicep) for always-on behavior

**Security:**
- Development: Container App ingress restricted by IP allowlist + Entra ID
- Production: Use internal ingress, private endpoints, WAF, and `minReplicas: 2`