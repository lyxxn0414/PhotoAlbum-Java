# Modernization Summary: 001-upgrade-spring-boot-3

## Task
Upgrade Spring Boot from 2.7.18 to 3.x (Spring Boot 3.4.5)

## Changes Made

### `pom.xml`
- Upgraded `spring-boot-starter-parent` from **2.7.18** → **3.4.5**
- Updated `java.version` from `1.8` → `17`
- Updated `maven.compiler.source` from `8` → `17`
- Updated `maven.compiler.target` from `8` → `17`

### `src/main/java/com/photoalbum/model/Photo.java`
- Migrated `javax.persistence.*` → `jakarta.persistence.*`
- Migrated `javax.validation.constraints.*` → `jakarta.validation.constraints.*`

## Notes
- `javax.imageio.ImageIO` in `PhotoServiceImpl.java` is part of the standard JDK (`java.desktop` module), **not** Jakarta EE — no change required.
- Oracle-native SQL queries in `PhotoRepository.java` (ROWNUM, NVL, TO_CHAR, analytical functions) were left untouched and remain fully functional.
- Spring Boot 3.4.5 bundles Hibernate 6.6.x, which maps `jakarta.persistence` annotations correctly for both Oracle and H2 dialects.

## Verification
- `mvn clean test` passed with zero test failures.
- Spring application context loaded successfully using the H2 in-memory test profile.
