# Modernization Summary: Deploy PhotoAlbum to Azure Container Apps

## Task ID
`003-deployment-azure-container-apps`

## Overview
This task migrated the PhotoAlbum Java application from Oracle Database to PostgreSQL and created all infrastructure-as-code, CI/CD pipeline, and deployment configuration required to run the application on **Azure Container Apps** with **Azure Database for PostgreSQL Flexible Server**.

Since the Azure CLI is not authenticated in this environment, actual Azure resource creation was not performed. All infrastructure code, deployment scripts, and application configuration changes are in place and ready for deployment once Azure credentials are configured.

---

## Changes Made

### 1. Database Migration: Oracle → PostgreSQL

#### `pom.xml`
- **Removed**: `com.oracle.database.jdbc:ojdbc8` (Oracle JDBC runtime dependency)
- **Added**: `org.postgresql:postgresql` (PostgreSQL JDBC runtime dependency, version managed by Spring Boot BOM)

#### `src/main/java/com/photoalbum/repository/PhotoRepository.java`
Replaced all Oracle-specific SQL constructs with PostgreSQL equivalents:

| Method | Oracle (Before) | PostgreSQL (After) |
|---|---|---|
| `findPhotosUploadedBefore` | `ROWNUM <= 10` subquery wrapping | `LIMIT 10` clause |
| `findPhotosUploadedAfter` | `NVL(FILE_PATH, 'default_path')` | `COALESCE(FILE_PATH, 'default_path')` |
| `findPhotosByUploadMonth` | `TO_CHAR(UPLOADED_AT, 'YYYY')` / `TO_CHAR(UPLOADED_AT, 'MM')` | `EXTRACT(YEAR FROM UPLOADED_AT)::text` / `LPAD(EXTRACT(MONTH FROM UPLOADED_AT)::text, 2, '0')` |
| `findPhotosWithPagination` | Oracle ROWNUM-based subquery pagination (`startRow`/`endRow`) | `LIMIT :pageSize OFFSET :offset` |
| `findPhotosWithStatistics` | No change needed (RANK() OVER, SUM() OVER are PostgreSQL-compatible) | — |

#### `src/main/java/com/photoalbum/model/Photo.java`
- `fileSize` column definition: `NUMBER(19,0)` → `BIGINT`
- `uploadedAt` column definition: `TIMESTAMP DEFAULT SYSTIMESTAMP` → `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`

#### `src/main/resources/application.properties`
- Updated datasource URL to `jdbc:postgresql://localhost:5432/photoalbum`
- Updated driver class to `org.postgresql.Driver`
- Updated JPA dialect to `org.hibernate.dialect.PostgreSQLDialect`
- Changed `ddl-auto` from `create` to `update`

#### `src/main/resources/application-docker.properties`
- Updated datasource URL to `jdbc:postgresql://postgres-db:5432/photoalbum`
- Updated driver class to `org.postgresql.Driver`
- Updated JPA dialect to `org.hibernate.dialect.PostgreSQLDialect`
- Changed `ddl-auto` from `create` to `update`
- Removed duplicate property entries

---

### 2. New Azure Configuration File

#### `src/main/resources/application-azure.properties` *(new)*
Spring Boot profile (`azure`) for Azure deployment that:
- Reads database connection details from environment variables (`AZURE_POSTGRESQL_CONNECTION_STRING`, `AZURE_POSTGRESQL_USERNAME`, `AZURE_POSTGRESQL_PASSWORD`)
- Provides sensible defaults for local development
- Configures file upload limits and allowed MIME types
- Sets production-appropriate log levels

---

### 3. Azure Infrastructure (Bicep)

#### `infra/main.bicep` *(new)*
Bicep template that provisions all required Azure resources:
- **Azure Container Registry (ACR)** – Basic SKU, admin user enabled, for storing the Docker image
- **Log Analytics Workspace** – 30-day retention, for Container Apps logging
- **Container Apps Environment** – Linked to Log Analytics for centralized log collection
- **Azure Database for PostgreSQL Flexible Server** – Burstable B1ms, version 16, 32 GB storage, no HA (cost-optimized for production starter)
- **PostgreSQL Database** – `photoalbum` database with UTF-8 / en_US.UTF8 collation
- **PostgreSQL Firewall Rule** – Allows Azure service-to-service connectivity
- **Container App** – External HTTPS ingress on port 8080, pulls image from ACR using admin credentials stored as secrets, injects PostgreSQL connection details as secrets/env vars, scales 1–3 replicas based on concurrent HTTP requests (threshold: 50)

All sensitive values (ACR password, PostgreSQL credentials) are stored as Container App secrets and referenced via `secretRef` — never stored in plain-text environment variables.

#### `infra/parameters.json` *(new)*
Non-secret deployment parameters:
- `appName`: `photoalbum`
- `environment`: `prod`
- `location`: `eastus`
- `postgresDatabaseName`: `photoalbum`
- `postgresAppUser`: `photoalbum`

#### `infra/deploy.sh` *(new)*
Bash deployment script that:
1. Validates Azure CLI login
2. Creates the resource group (idempotent)
3. Generates random passwords for PostgreSQL admin and app user
4. Deploys Bicep infrastructure
5. Builds and pushes the Docker image to ACR
6. Updates the Container App to use the new image

---

### 4. GitHub Actions CI/CD Workflow

#### `.github/workflows/deploy-azure.yml` *(new)*
Automated deployment pipeline triggered on pushes to `main` or manually via `workflow_dispatch`:
1. **Build** – Java 17 (Temurin), Maven package (skip tests for speed)
2. **Azure Login** – Using `AZURE_CREDENTIALS` secret (service principal JSON)
3. **Infrastructure Deploy** – Bicep deployment (idempotent); extracts ACR name, login server, Container App name, and URL as step outputs
4. **Docker Build & Push** – Tagged with both commit SHA and `latest`
5. **Container App Update** – Rolls the app to the new image revision

#### Required GitHub Secrets
| Secret | Description |
|---|---|
| `AZURE_CREDENTIALS` | Azure service principal credentials (JSON from `az ad sp create-for-rbac`) |
| `POSTGRES_ADMIN_PASSWORD` | Strong password for the PostgreSQL admin user |
| `POSTGRES_APP_PASSWORD` | Password for the application's PostgreSQL user |

---

## Build Verification

Maven build completed successfully:
```
[INFO] BUILD SUCCESS
[INFO] Total time: 6.030 s
```

The application compiles and packages correctly with the PostgreSQL driver replacing the Oracle driver.

---

## Deployment Instructions

### Prerequisites
1. Azure CLI installed and authenticated (`az login`)
2. Docker installed and running
3. Resource group or permission to create one

### Manual Deployment
```bash
# Set environment variables (optional overrides)
export RESOURCE_GROUP="photoalbum-rg"
export LOCATION="eastus"

# Run deployment script
./infra/deploy.sh
```

### GitHub Actions Deployment
1. Create an Azure service principal:
   ```bash
   az ad sp create-for-rbac --name "photoalbum-github-actions" \
     --role contributor \
     --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/photoalbum-rg \
     --sdk-auth
   ```
2. Add the output JSON as the `AZURE_CREDENTIALS` GitHub secret
3. Add `POSTGRES_ADMIN_PASSWORD` and `POSTGRES_APP_PASSWORD` GitHub secrets
4. Push to `main` branch — the workflow runs automatically

---

## Architecture

```
GitHub Actions (CI/CD)
        │
        ▼
Azure Container Registry
        │  (pull image)
        ▼
Azure Container Apps Environment
  └── Container App (photoalbum-app-prod)
        │  port 8080, HTTPS
        │  SPRING_PROFILES_ACTIVE=azure
        ▼
Azure Database for PostgreSQL Flexible Server
  └── Database: photoalbum
```

## Resource Naming
Resources use a `uniqueString(resourceGroup().id)` suffix for globally unique names:
- ACR: `photoalbumacr<suffix>`
- Log Analytics: `photoalbum-logs-<suffix>`
- PostgreSQL: `photoalbum-db-<suffix>`
- Container Apps Env: `photoalbum-env-prod`
- Container App: `photoalbum-app-prod`
