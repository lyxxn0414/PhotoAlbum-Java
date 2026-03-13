# Modernization Plan: Deploy Photo Album to Azure Container Apps

**Project**: Photo Album

---

## Technical Framework

- **Language**: Java 21
- **Framework**: Spring Boot 3.4.0
- **Build Tool**: Maven 3.9
- **Database**: PostgreSQL (with Azure Managed Identity support already configured)
- **Key Dependencies**: Spring Data JPA, Thymeleaf, Azure Identity Extensions

---

## Overview

This migration deploys the Photo Album application to Azure Container Apps using Azure Developer CLI (azd). The application currently runs locally with Docker Compose using PostgreSQL and already has an Azure profile configured with Managed Identity for passwordless PostgreSQL authentication. The new architecture will:

- Provision Azure infrastructure (Container Apps, Azure Database for PostgreSQL) using Bicep templates integrated with azd
- Leverage the existing Dockerfile for container image builds
- Deploy the containerized application to Azure Container Apps with azd

The migration follows a phased approach: generate infrastructure as code, validate containerization, and deploy to Azure.

---

## Migration Impact Summary

| Application | Original Service         | New Azure Service                  | Authentication | Comments                          |
|-------------|--------------------------|------------------------------------|----------------|-----------------------------------|
| Photo Album | Local Docker runtime     | Azure Container Apps               | N/A            | Deploy using azd                  |
| Photo Album | Local PostgreSQL (Docker)| Azure Database for PostgreSQL      | Managed Identity | Azure profile already configured |

---

## Tasks

1. Generate Azure infrastructure (Bicep) for Azure Container Apps and Azure Database for PostgreSQL with azd integration
2. Validate and update Dockerfile for Azure Container Apps deployment
3. Deploy application to Azure Container Apps
