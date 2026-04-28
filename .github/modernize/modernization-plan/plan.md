# Modernization Plan: Deploy PhotoAlbum to Azure

**Project**: PhotoAlbum-Java

---

## Technical Framework

- **Language**: Java 17
- **Framework**: Spring Boot 3.4.4
- **Build Tool**: Maven 3.9
- **Database**: Oracle DB (photos stored as BLOBs, Oracle-specific native SQL queries)
- **Key Dependencies**: Spring Data JPA, Thymeleaf, Oracle JDBC (ojdbc11), H2 (test/azure profile), Commons IO

---

## Overview

This migration deploys the PhotoAlbum Java application to Azure with a database migration from Oracle to Azure SQL Database. The application is a Spring Boot photo gallery that stores photos as database BLOBs and uses Oracle-specific native SQL queries (ROWNUM, TO_CHAR, NVL, analytical functions). The modernization will:

- Migrate the database layer from Oracle DB to Azure SQL Database, rewriting Oracle-specific native queries and updating JPA configuration
- Configure Managed Identity authentication for secure, credential-free connectivity to Azure SQL Database
- Deploy the containerized application to Azure Container Apps for a scalable, serverless hosting experience

The migration follows a phased approach: first migrating the database layer, then securing authentication with Managed Identity, and finally deploying to Azure Container Apps.

---

## Migration Impact Summary

| Application | Original Service | New Azure Service      | Authentication   | Comments                           |
|-------------|------------------|------------------------|------------------|------------------------------------|
| PhotoAlbum  | Oracle DB        | Azure SQL Database     | Managed Identity | Migrate Oracle-specific SQL        |
| PhotoAlbum  | Local/Docker     | Azure Container Apps   | Managed Identity | Deploy containerized app           |

---

## Tasks

### Task 1: Migrate Oracle DB to Azure SQL Database
- **Type**: Transform
- **Description**: Migrate Oracle-specific database code to Azure SQL Database compatible code, including rewriting native queries, updating JPA/Hibernate dialect, and replacing the Oracle JDBC driver

### Task 2: Configure Managed Identity for Azure SQL
- **Type**: Transform
- **Skill**: migration-mi-azure-sql
- **Description**: Configure Managed Identity authentication for secure, credential-free connectivity to Azure SQL Database

### Task 3: Deploy to Azure Container Apps
- **Type**: Deployment
- **Target**: Azure Container Apps
- **Skill**: azcli-containerapp-deploy
- **Description**: Deploy the PhotoAlbum application to Azure Container Apps using the existing Dockerfile
