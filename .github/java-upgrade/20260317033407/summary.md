
# Upgrade Java Project

## 🖥️ Project Information
- **Project path**: C:\Users\yueli6\Desktop\PhotoAlbum-Java
- **Java version**: 17
- **Build tool type**: Maven
- **Build tool path**: C:\Program Files\Apache\apache-maven-3.9.6\bin

## 🎯 Goals

- Upgrade Java to 17
- Upgrade Spring Boot to 3.4.x

## 🔀 Changes

### Test Changes
|     | Total | Passed | Failed | Skipped | Errors |
|-----|-------|--------|--------|---------|--------|
| Before | 1 | 1 | 0 | 0 | 0 |
| After | 1 | 1 | 0 | 0 | 0 |
### Dependency Changes


#### Upgraded Dependencies
| Dependency | Original Version | Current Version | Module |
|------------|------------------|-----------------|--------|
| org.springframework.boot:spring-boot-starter-web | 2.7.18 | 3.4.4 | photo-album |
| org.springframework.boot:spring-boot-starter-thymeleaf | 2.7.18 | 3.4.4 | photo-album |
| org.springframework.boot:spring-boot-starter-data-jpa | 2.7.18 | 3.4.4 | photo-album |
| org.springframework.boot:spring-boot-starter-validation | 2.7.18 | 3.4.4 | photo-album |
| org.springframework.boot:spring-boot-starter-json | 2.7.18 | 3.4.4 | photo-album |
| org.springframework.boot:spring-boot-starter-test | 2.7.18 | 3.4.4 | photo-album |
| com.h2database:h2 | 2.1.214 | 2.3.232 | photo-album |
| org.springframework.boot:spring-boot-devtools | 2.7.18 | 3.4.4 | photo-album |
| Java | 8 | 17 | Root Module |

#### Added Dependencies
|   Dependency   | Version | Module |
|----------------|---------|--------|
| com.oracle.database.jdbc:ojdbc11 | 23.5.0.24.07 | photo-album |

#### Removed Dependencies
|   Dependency   | Version | Module |
|----------------|---------|--------|
| com.oracle.database.jdbc:ojdbc8 | 21.5.0.0 | photo-album |

### Code commits

All code changes have been committed to branch `main`, here are the details:
26 files changed, 15 insertions(+), 795 deletions(-)

- 48ef734 -- Milestone 1: Upgrade Spring Boot 2.7.18 to 3.3.13 and Java 8 to 17

- 5eb7e3a -- Milestone 2: Upgrade Spring Boot 3.3.13 to 3.4.4

- 6087f4b -- fix issues
### Potential Issues

#### CVEs
- commons-io:commons-io:2.11.0:
  - [**HIGH**][CVE-2024-47554](https://github.com/advisories/GHSA-78wr-2p64-hpwj): Apache Commons IO: Possible denial of service attack on untrusted input to XmlStreamReader
