# Modernization Plan: Deploy Photo Album to Azure Container Apps

**Project**: Photo Album

---

## Technical Framework

- **Language**: Java 17
- **Framework**: Spring Boot 3.4.4
- **Build Tool**: Maven 3.9
- **Database**: SQL Server (Azure SQL Edge in Docker)
- **Key Dependencies**: Spring Data JPA, Hibernate,
  Thymeleaf, Spring Boot Starter Web

---

## Overview

This migration deploys the Photo Album application to
Azure Container Apps. The application currently runs
locally via Docker Compose with an Azure SQL Edge database.
The new architecture will:

- Containerize and deploy the application to Azure
  Container Apps for a fully managed serverless container
  hosting experience
- Provision the required Azure infrastructure using Bicep
- Enable scalable, cloud-native deployment with minimal
  operational overhead

The migration follows a single-phase deployment approach
since no code-level transformations are required.

---

## Migration Impact Summary

| Application | Original Service | New Azure Service       | Authentication      | Comments                        |
|-------------|------------------|-------------------------|---------------------|---------------------------------|
| Photo Album | Docker Compose   | Azure Container Apps    | Managed Identity    | Deploy existing containerized   |
|             | (local)          |                         |                     | app to ACA                      |

---

## Tasks

### Task 1: Deploy to Azure Container Apps

Deploy the Photo Album application to Azure Container
Apps. This includes containerization, provisioning the
required Azure resources, and deploying the application
using Azure CLI.

- **Skill**: `azcli-containerapp-deploy` (builtin)
- **Target**: Azure Container Apps
- **Deployment Tool**: Bicep
