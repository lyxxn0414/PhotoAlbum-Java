# Modernization Plan: Deploy Photo Album to Azure

**Project**: Photo Album

---

## Technical Framework

- **Language**: Java 21
- **Framework**: Spring Boot 3.4.0
- **Build Tool**: Maven 3.9
- **Database**: PostgreSQL (with Azure Identity Extensions for Managed Identity)
- **Key Dependencies**: Spring Data JPA, Thymeleaf, Spring Boot Actuator,
  Azure Identity Extensions

---

## Overview

> This migration deploys the Photo Album application to Azure using
> Azure Container Apps. The application currently runs locally with
> PostgreSQL and is already containerized with a multi-stage Dockerfile.
> The new architecture will:
>
> - Provision Azure infrastructure (Container Apps, ACR, PostgreSQL
>   Flexible Server, Key Vault, Managed Identity) using Bicep IaC
> - Containerize the application and push the image to Azure Container
>   Registry
> - Deploy the application to Azure Container Apps with passwordless
>   PostgreSQL authentication via Managed Identity
>
> The migration follows a phased approach: infrastructure provisioning,
> containerization, and deployment.

---

## Migration Impact Summary

| Application | Original Service   | New Azure Service              | Authentication   | Comments                          |
|-------------|--------------------|--------------------------------|------------------|-----------------------------------|
| Photo Album | Local PostgreSQL   | Azure Database for PostgreSQL  | Managed Identity | Passwordless auth via Service     |
|             |                    | Flexible Server                |                  | Connector                         |
| Photo Album | Local Docker       | Azure Container Apps           | Managed Identity | Deploy via ACR with Bicep IaC     |
| Photo Album | N/A                | Azure Container Registry       | Managed Identity | Store container images            |
| Photo Album | N/A                | Azure Key Vault                | Managed Identity | Secrets management                |

---

## Tasks

1. **Generate Azure Infrastructure (Bicep)** — Generate Bicep IaC files
   to provision all required Azure resources including Container Apps
   Environment, Container Registry, PostgreSQL Flexible Server,
   Key Vault, Managed Identity, and Log Analytics.

2. **Containerize Application** — Validate and use the existing
   multi-stage Dockerfile to build the application container image
   for Azure Container Apps deployment.

3. **Deploy to Azure Container Apps** — Deploy the containerized
   application to Azure Container Apps with the provisioned
   infrastructure, configuring Service Connector for passwordless
   PostgreSQL authentication.
