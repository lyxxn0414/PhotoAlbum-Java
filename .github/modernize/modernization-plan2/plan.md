# Modernization Plan: Deploy PhotoAlbum to Azure

**Project**: PhotoAlbum

---

## Technical Framework

- **Language**: Java 17
- **Framework**: Spring Boot 3.4.4
- **Build Tool**: Maven 3.9
- **Database**: Oracle DB (production), H2 in-memory (Azure profile)
- **Key Dependencies**: Spring Data JPA, Thymeleaf, Spring Boot Validation, Commons IO

---

## Overview

This migration deploys the PhotoAlbum Java application to Azure Container Apps. The application currently runs locally via Docker Compose with an Oracle database and has an existing Azure profile using H2 in-memory database. The new architecture will:

- Containerize the application using the existing Dockerfile and deploy it to Azure Container Apps for a fully managed, serverless container hosting experience
- Leverage the existing Bicep infrastructure templates for provisioning Azure resources including Container Registry, Container Apps Environment, Log Analytics, and Application Insights
- Enable automatic scaling and HTTPS ingress for production-ready deployment

The migration follows a two-phase approach: containerization verification followed by Azure deployment.

---

## Migration Impact Summary

| Application | Original Service     | New Azure Service     | Authentication  | Comments                          |
|-------------|----------------------|-----------------------|-----------------|-----------------------------------|
| PhotoAlbum  | Local Docker Compose | Azure Container Apps  | Managed Identity| Deploy containerized app to Azure |
| PhotoAlbum  | Local Oracle DB      | H2 In-Memory (Azure)  | N/A             | Uses existing azure profile       |

---

## Tasks

1. **Containerization** — Verify and update the existing Dockerfile for Azure Container Apps deployment
2. **Deployment** — Deploy the PhotoAlbum application to Azure Container Apps using Bicep infrastructure
