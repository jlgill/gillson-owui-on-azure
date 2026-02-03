# Copilot Instructions: Open WebUI on Azure

## Project Overview

This is an Azure Infrastructure-as-Code (IaC) project that deploys [Open WebUI](https://github.com/open-webui/open-webui) on Azure with enterprise-grade security. It uses a **hub-spoke architecture** with Bicep and Azure Verified Modules (AVM).

**Reference Articles:**
- [Part 1: Architecture & Deployment](https://rios.engineer/open-webui-on-azure-part-1-architecture-deployment/)
- [Part 2: API Management ❤️ AI](https://rios.engineer/open-webui-on-azure-part-2-api-management-ai/)

## Architecture (Critical Context)

**Hub resources** ([infra/bicep/main.bicep](infra/bicep/main.bicep)):
- Application Gateway (SSL termination, custom domain)
- API Management (internal mode, AI gateway with token tracking)
- VNet peering, Private DNS zones, NSGs

**Spoke resources** ([infra/bicep/app.bicep](infra/bicep/app.bicep)):
- Azure Container Apps (Open WebUI)
- Azure AI Foundry (GPT models via Managed Identity)
- PostgreSQL Flexible Server (private endpoint)
- Entra ID App Registration (OAuth/OIDC)
- Key Vault (SSL certificates)

## Authentication & Token Flow (CRITICAL)

This solution uses **OAuth session tokens** for user attribution and security. Understanding this flow is essential:

### How Authentication Works

1. **User logs into Open WebUI** via Entra ID OAuth/OIDC
2. **Open WebUI stores the JWT** in browser local storage (session token)
3. **When user sends a chat**, Open WebUI makes an API call to APIM with:
   - `Authorization: Bearer <JWT>` header (user's OAuth token)
   - `api-key: <subscription-key>` header (APIM subscription)
4. **APIM validates the token** using `validate-azure-ad-token` policy:
   - Checks `aud` (audience) matches either the App ID GUID or `api://app-open-webui`
   - Checks `iss` (issuer) matches the tenant
   - Validates `roles` claim contains `admin` or `user`
5. **APIM extracts claims** for per-user metrics:
   - `preferred_username` → User ID tracking & rate limiting
   - `ipaddr` → Client IP tracking
6. **APIM calls Foundry** using Managed Identity (no secrets)

### Why Tokens Matter

APIM policies use the JWT to:
- **Attribute usage to specific users** (not just subscriptions)
- **Enforce per-user token rate limits** (`llm-token-limit` policy)
- **Track custom metrics** per user, per model for analytics/chargebacks
- **Validate authorization** before allowing Foundry access

### Open WebUI Connection Configuration

The connection **MUST** be configured in **Admin Settings → Connections** (global connection):

| Setting | Value | Notes |
|---------|-------|-------|
| **API Base URL** | `https://<apim-name>.azure-api.net/openai/v1` | APIM endpoint |
| **API Type** | `OpenAI` | NOT Azure OpenAI |
| **Auth** | `OAuth` | **CRITICAL** - enables token forwarding |
| **Headers** | `{"api-key": "<subscription-key>"}` | APIM subscription key |
| **Model Ids** | Your models (e.g., `gpt-4o`) | Must match Foundry deployments |

> **⚠️ Important**: User-created connections (under user profile) do NOT support custom headers, so they cannot pass the APIM subscription key. Always use the global admin connection.

### Entra App Roles

The Entra App Registration defines two roles that flow through the JWT:
- `admin` - Full Open WebUI admin access
- `user` - Standard user access

These roles are validated by APIM's `validate-azure-ad-token` policy with `required-claims`.

### OAUTH_SCOPES (Critical for Token Audience)

The `OAUTH_SCOPES` environment variable in the Container App determines which resource the OAuth token is requested for. The scope **must** include the app's custom API scope to get a token with the correct audience:

- ✅ `api://app-open-webui/user_impersonation` → token `aud` = `api://app-open-webui`
- ❌ Only `User.Read` (Graph scope) → token `aud` = `https://graph.microsoft.com` (APIM rejects)

## 3-Step Deployment Model

The deployment is **sequential and stateful** - outputs from one step become inputs to the next:

1. **Step 1**: Deploy hub (`main.bicep`) with `parConfigureFoundry=false` → creates VNet, APIM shell
2. **Step 2**: Deploy spoke (`app.bicep`) → creates Foundry, ACA, PostgreSQL, Entra app
3. **Step 3**: Redeploy hub with spoke outputs + `parConfigureFoundry=true` → configures APIM backend, VNet peering, RBAC

## Deployment Commands (CRITICAL)

**Always use unique deployment names** with the `--name` parameter to avoid conflicts with in-progress or existing deployments. Use a timestamp or descriptive suffix.

### Hub Deployment (main.bicep)
```powershell
# Initial hub deployment (Step 1)
az deployment sub create `
  --location westus `
  --name "hub-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
  --template-file .\infra\bicep\main.bicep `
  --parameters .\infra\bicep\main.bicepparam

# Hub redeploy after spoke (Step 3)
az deployment sub create `
  --location westus `
  --name "hub-configure-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
  --template-file .\infra\bicep\main.bicep `
  --parameters .\infra\bicep\main.bicepparam
```

### Spoke Deployment (app.bicep)
```powershell
# Spoke deployment (Step 2)
az deployment sub create `
  --location westus `
  --name "spoke-$(Get-Date -Format 'yyyyMMdd-HHmmss')" `
  --template-file .\infra\bicep\app.bicep `
  --parameters .\infra\bicep\app.bicepparam
```

> **⚠️ Important**: Without unique `--name` values, deployments may fail with "deployment already exists" errors if a previous deployment with the same name is still running or recently completed.

## Key Patterns

### Shared Configuration
All configuration is centralized in [infra/bicep/shared/config.bicep](infra/bicep/shared/config.bicep). Both `.bicepparam` files import from here:
```bicep
import { sharedConfig } from './shared/config.bicep'
param parLocation = sharedConfig.location
```

### Placeholder Detection
The hub detects first deployment via placeholder markers to handle missing spoke resources gracefully:
```bicep
import { placeholderMarker } from './shared/config.bicep'
var varIsFirstDeployment = parContainerAppFqdn == placeholderMarker || parContainerAppStaticIp == placeholderMarker
```

### Auto-Derived Names
Spoke resource names are derived from `parSpokeNamePrefix` in the hub to ensure consistency without manual duplication:
```bicep
var varSpokeKeyVaultName = take('${parSpokeNamePrefix}-kv-${varSpokeUniqueSuffix}', 24)
```

### Custom Types
Use types from [infra/bicep/shared/types.bicep](infra/bicep/shared/types.bicep) for parameters:
```bicep
import { FoundryDeploymentType, PostgresConfigType, TagsType } from './shared/types.bicep'
```

## Bicep Conventions

- **Target scope**: `subscription` for main deployments (creates resource groups)
- **Module source**: Use `br/public:avm/` prefix for Azure Verified Modules
- **Graph extension**: Required for Entra app registration: `extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:1.0.0'`
- **Naming**: 3-24 chars for Key Vault, 3-21 chars for APIM/AppGW, use `uniqueString()` for global uniqueness
- **MARK comments**: Use `// MARK: - Section Name` for code organization

### Azure Service Lifecycle

**Before adding Azure resources**, always verify the service is not deprecated or retired:

1. **Check [Azure Updates](https://azure.microsoft.com/en-us/updates/?query=retirement)** - Filter by "Retirements" to see scheduled service deprecations
2. **Check the [Azure Retirement Workbook](https://aka.ms/ServicesRetirementWorkbook)** - Shows retirements affecting your subscriptions
3. **Check [Azure service lifecycle documentation](https://learn.microsoft.com/en-us/lifecycle/products/?terms=azure)** - Official lifecycle status

> **⚠️ Lesson Learned**: Bing Search APIs (`Microsoft.Bing/accounts`) were retired August 11, 2025. Always verify service availability before implementing Azure resource types, especially those without published Bicep/ARM schemas.

**Red flags that a service may be deprecated:**
- No published ARM/Bicep schema (requires `#disable-next-line BCP081`)
- Limited recent documentation updates
- Microsoft recommending alternative services
- "Preview" services older than 2 years without GA announcement

## APIM Policies

Policies in [infra/bicep/policies/](infra/bicep/policies/) use:
- `validate-azure-ad-token` with named values: `{{tenant-id}}`, `{{openwebui-app-id}}`
- `llm-emit-token-metric` for AI Gateway analytics with custom dimensions:
  - `Client IP address` - from `ipaddr` JWT claim
  - `User ID` - from `preferred_username` JWT claim
  - `Model` - extracted from request body
  - `Subscription ID` / `API ID` - APIM context
- `llm-token-limit` for per-user token rate limiting (counter-key = `preferred_username`)
- `authentication-managed-identity` for backend auth to Foundry (no secrets)

### Policy Flow
```
Inbound:
  1. Extract model from request body (set-variable)
  2. Validate Azure AD token (tenant, audience, roles)
  3. Emit LLM token metrics (custom dimensions)
  4. Apply token rate limit (per-user)
  5. Set backend service (Foundry)
  6. Authenticate with Managed Identity
```

## Troubleshooting

### "Azure AD JWT not present" / 401 Errors

**Symptom**: APIM returns 401 with `TokenNotPresent` in `ApiManagementGatewayLogs`

**Cause**: Open WebUI isn't forwarding the user's OAuth token to APIM

**Fix**: Check the Open WebUI connection configuration:
1. **Auth must be `OAuth`** - this enables token forwarding
2. **Must be a global admin connection** - user connections don't support custom headers
3. **User must be logged in via Entra** - OAuth token is only available after login

**Diagnostic Query**:
```kql
ApiManagementGatewayLogs
| where TimeGenerated > ago(1h)
| project TimeGenerated, ResponseCode, LastErrorMessage, LastErrorReason
| where ResponseCode == 401
```

### "Role claim not found" / 403 Errors

**Symptom**: Token is present but APIM rejects with role validation failure

**Cause**: User doesn't have `admin` or `user` role assigned in Entra

**Fix**:
1. Azure Portal → Entra ID → Enterprise Applications → `app-open-webui`
2. Users and groups → Assign user/group to appropriate role

### LLM Metrics Not Appearing

**Symptom**: No data in `customMetrics` table or APIM LLM Analytics dashboard

**Cause**: Diagnostic settings not configured or OAuth not enabled

**Fix**:
1. Verify APIM diagnostic settings include "Logs related to generative AI gateway"
2. Verify Application Insights is connected with Managed Identity
3. Confirm requests are using OAuth (tokens needed for claim extraction)

**Diagnostic Query**:
```kql
customMetrics
| where timestamp > ago(1h)
| extend UserID = tostring(customDimensions["User ID"])
| extend Model = tostring(customDimensions["Model"])
| project timestamp, name, value, UserID, Model
```

## Common Tasks

**Update network config**: Edit `sharedConfig` in `shared/config.bicep`

**Add AI model**: Add to `parFoundryDeployments` array in `app.bicepparam`:
```bicep
param parFoundryDeployments = [{
  name: 'gpt-4o'
  model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-08-06' }
  sku: { name: 'GlobalStandard', capacity: 10 }
}]
```

**Modify APIM policy**: Edit XML in `infra/bicep/policies/openai-api.xml`, loaded via `loadTextContent()`

## Files to Never Edit Directly

- `.bicepparam` resource-specific values → update `shared/config.bicep` instead
- SSL certificates in `infra/bicep/cert/` → use `create-origin-cert.ps1` script

## Azure Resource Reference

Use these values when debugging or querying Azure resources:

| Resource | Value |
|----------|-------|
| **Subscription ID** | `1abe24d3-1140-4570-a5a3-64dbaa62fc93` |
| **Subscription Name** | Personal Azure Subscription |
| **Tenant ID** | `1b4ec955-c987-44c3-a62f-d1cd054d1ddc` |
| **Spoke Resource Group** | `rg-owui-app` |
| **Container App Name** | `owui-app-aca` |
| **Container App Environment** | `owuiappacaenv` |
| **Log Analytics Workspace** | `owui-app-law` |
| **Custom Domain** | `openwebui.gillson.us` |

## Container App Debugging

### Quick Health Check

Check if the container is running:
```bash
az containerapp show --name owui-app-aca --resource-group rg-owui-app \
  --subscription 1abe24d3-1140-4570-a5a3-64dbaa62fc93 \
  --query "{status: properties.runningStatus, revision: properties.latestRevisionName, replicas: properties.template.scale}"
```

### Real-Time Log Streaming

**Console logs** (application output):
```bash
az containerapp logs show --name owui-app-aca --resource-group rg-owui-app \
  --subscription 1abe24d3-1140-4570-a5a3-64dbaa62fc93 \
  --type console --follow --tail 100
```

**System logs** (container lifecycle events):
```bash
az containerapp logs show --name owui-app-aca --resource-group rg-owui-app \
  --subscription 1abe24d3-1140-4570-a5a3-64dbaa62fc93 \
  --type system --follow --tail 50
```

### Common Container App Issues

#### Container Crash Loop (cgroup errors)

**Symptom**: `ContainerCreateFailure` with `Invalid argument : sys/fs/cgroup/cpu/default/cpu_cfs_quota_us`

**Cause**: CPU resource allocation too low (e.g., 0.5 cores)

**Fix**: Increase CPU to at least 1.0 core:
```bash
az containerapp update --name owui-app-aca --resource-group rg-owui-app \
  --subscription 1abe24d3-1140-4570-a5a3-64dbaa62fc93 \
  --cpu 1.0 --memory 2Gi
```

#### Startup Probe Failures

**Symptom**: Repeated `ProbeFailed` events in system logs

**Cause**: Container taking too long to start, or health endpoint not responding

**Fix**: Check console logs for startup errors, verify database connectivity, increase probe timeout if needed

#### Resource Configuration

Check current resources:
```bash
az containerapp show --name owui-app-aca --resource-group rg-owui-app \
  --subscription 1abe24d3-1140-4570-a5a3-64dbaa62fc93 \
  --query "properties.template.containers[0].resources"
```

Recommended minimum for Open WebUI:
- **CPU**: 1.0 cores
- **Memory**: 2Gi
- **Ephemeral Storage**: 4Gi (auto-scales with memory)

### Revision Management

List all revisions:
```bash
az containerapp revision list --name owui-app-aca --resource-group rg-owui-app \
  --subscription 1abe24d3-1140-4570-a5a3-64dbaa62fc93 \
  --query "[].{name:name, active:properties.active, created:properties.createdTime}" -o table
```

Restart the container (creates new replica):
```bash
az containerapp revision restart --name owui-app-aca --resource-group rg-owui-app \
  --subscription 1abe24d3-1140-4570-a5a3-64dbaa62fc93 \
  --revision <revision-name>
```

## Log Locations

| Log Type | Workspace | Table |
|----------|-----------|-------|
| APIM Gateway Logs | `open-webui-law` (hub) | `ApiManagementGatewayLogs` |
| APIM LLM Metrics | `open-webui-law` (hub) | `customMetrics` |
| Container App Logs | `owui-app-law` (spoke) | `ContainerAppConsoleLogs` |
| Container App System | `owui-app-law` (spoke) | `ContainerAppSystemLogs` |

## Quick Reference KQL Queries

**Check recent APIM errors:**
```kql
ApiManagementGatewayLogs
| where TimeGenerated > ago(2h)
| where ResponseCode >= 400
| project TimeGenerated, ApiId, ResponseCode, LastErrorMessage, LastErrorReason
| order by TimeGenerated desc
```

**Per-user token usage:**
```kql
customMetrics
| where timestamp > ago(24h)
| extend UserID = tostring(customDimensions["User ID"])
| extend Model = tostring(customDimensions["Model"])
| summarize TotalTokens = sum(value) by UserID, Model
| order by TotalTokens desc
```
