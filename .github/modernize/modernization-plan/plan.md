# Modernization Plan: Deploy PhotoAlbum to Azure

**Project**: PhotoAlbum-Java

---

## Technical Framework

- **Language**: Java 8
- **Framework**: Spring Boot 2.7.18
- **Build Tool**: Maven 3.9
- **Database**: Oracle Database (photos stored as BLOBs with Oracle-specific SQL)
- **Key Dependencies**: Spring Data JPA, Thymeleaf, Spring Boot Web, Commons IO

---

## Overview

This migration deploys the PhotoAlbum Java application to Azure. The application currently runs as a Spring Boot 2.7.18 web application on Java 8 with an Oracle database backend, using Docker for containerization. The new architecture will:

- Upgrade the application to Spring Boot 3.x with JDK 17 to ensure long-term support and compatibility with modern Azure services
- Update the existing Dockerfile for the upgraded Java runtime
- Deploy the containerized application to Azure Container Apps for a fully managed, serverless container hosting experience

The migration follows a phased approach: upgrade first, then containerize, then deploy.

---

## Migration Impact Summary

| Application   | Original Service | New Azure Service      | Authentication      | Comments                        |
|---------------|------------------|------------------------|---------------------|---------------------------------|
| PhotoAlbum    | Local Docker     | Azure Container Apps   | Managed Identity    | Deploy containerized app        |

---

## Clarifications

The following items were not explicitly requested but may be needed for a complete implementation:

1. **Database Migration**: The application currently uses Oracle Database with Oracle-specific SQL (ROWNUM, NVL, TO_CHAR, RANK() OVER). Oracle is not natively available as a managed Azure service.
   - **Why needed**: The deployed application needs a database to function. Without addressing this, the app cannot connect to a database on Azure.
   - **Options**:
     - Migrate from Oracle to Azure Database for PostgreSQL (requires SQL and code changes)
     - Host Oracle on an Azure VM (no code changes but higher operational overhead)
     - Use a third-party Oracle cloud service accessible from Azure
   - **Recommendation**: Migrate to Azure Database for PostgreSQL using the available migration skill. Please confirm if you'd like to include this in the plan.
