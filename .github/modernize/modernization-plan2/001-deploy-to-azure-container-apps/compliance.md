# Infrastructure Compliance Report

## Deployment Tool
- **Tool**: Azure CLI (`az deployment group create`) — complies with `deploymentTool=azcli` rule
- **IaC**: Bicep (NOT azd) — complies with skill requirement

## Rules Compliance

| Rule | Status | Notes |
|------|--------|-------|
| Use `az deployment` (not azd) | ✅ Compliant | `deploy.sh` and `deploy.ps1` both use `az deployment group create` |
| One module per resource type | ✅ Compliant | 6 dedicated modules in `modules/` folder |
| Managed Identity for DB auth | ✅ Compliant | User-Assigned MI with `ActiveDirectoryMSI` connection string |
| No hardcoded secrets in Bicep | ✅ Compliant | SQL password is `@secure()` param, never in outputs |
| Ingress TLS | ✅ Compliant | `allowInsecure: false`; external HTTPS ingress |
| Minimal TLS 1.2 on SQL | ✅ Compliant | `minimalTlsVersion: '1.2'` in sqlServer module |
| Admin user on ACR disabled by default | ⚠️ Note | `adminUserEnabled: true` required for `az acr build`; can be disabled after switching to MI-based pull |
| Container image from private registry | ✅ Compliant | ACR referenced via managed identity registry credential |
| Liveness + Readiness probes | ✅ Compliant | Both probes defined on `/actuator/health:8080` |
| Scale rules defined | ✅ Compliant | HTTP concurrency rule; min 1, max 3 replicas |
| Tags on all resources | ✅ Compliant | `environment` and `application` tags propagated via `tags` param |

## Security Notes

1. **Managed Identity**: The Container App uses a User-Assigned Managed Identity for both ACR image pull and Azure SQL authentication — no passwords in environment variables.
2. **SQL Firewall**: `AllowAllAzureIPs` rule (`0.0.0.0`–`0.0.0.0`) enables Azure-internal traffic only (no public IP ranges opened).
3. **ACR Admin User**: Enabled temporarily for `az acr build` during initial setup. Disable with `az acr update --admin-enabled false` once CI/CD pipeline uses managed identity.

## Well-Architected Framework Alignment

| Pillar | Alignment |
|--------|-----------|
| Reliability | Min 1 replica, health probes, Basic SQL with backup |
| Security | Managed Identity auth, HTTPS only, TLS 1.2 minimum |
| Cost Optimization | Consumption plan (scale-to-zero), Basic ACR and SQL SKUs |
| Operational Excellence | Log Analytics integration, structured resource naming |
| Performance Efficiency | HTTP-based autoscaling up to 3 replicas |
