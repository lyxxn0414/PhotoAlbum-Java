# Upgrade Progress

  ### ✅ Generate Upgrade Plan
  - [[View Log]](logs\1.generatePlan.log)
  
  <details>
      <summary>[ click to toggle details ]</summary>
  
  - ###
    ### ✅ Install JDK 8
  </details>

  ### ✅ Confirm Upgrade Plan
  - [[View Log]](logs\2.confirmPlan.log)

  ### ✅ Setup Development Environment
  - [[View Log]](logs\3.setupEnvironment.log)

  ### ✅ PreCheck
  - [[View Log]](logs\4.precheck.log)
  
  <details>
      <summary>[ click to toggle details ]</summary>
  
  - ###
    ### ✅ Precheck - Build project
    - [[View Log]](logs\4.1.precheck-buildProject.log)
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Command
    `mvn clean test-compile -q -B -fn`
    </details>
  
    ### ✅ Precheck - Validate CVEs
    - [[View Log]](logs\4.2.precheck-validateCves.log)
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### CVE issues
    - Dependency `commons-io:commons-io:2.11.0` has **1** known CVEs:
      - [CVE-2024-47554](https://github.com/advisories/GHSA-78wr-2p64-hpwj): Apache Commons IO: Possible denial of service attack on untrusted input to XmlStreamReader
        - **Severity**: **HIGH**
        - **Details**: Uncontrolled Resource Consumption vulnerability in Apache Commons IO.
          
          The `org.apache.commons.io.input.XmlStreamReader` class may excessively consume CPU resources when processing maliciously crafted input.
          
          
          This issue affects Apache Commons IO: from 2.0 before 2.14.0.
          
          Users are recommended to upgrade to version 2.14.0 or later, which fixes the issue.
    - Dependency `com.h2database:h2:2.1.214` has **1** known CVEs:
      - [CVE-2022-45868](https://github.com/advisories/GHSA-22wj-vf5f-wrvj): Password exposure in H2 Database 
        - **Severity**: **HIGH**
        - **Details**: The web-based admin console in H2 Database Engine through 2.1.214 can be started via the CLI with the argument -webAdminPassword, which allows the user to specify the password in cleartext for the web admin console. Consequently, a local user (or an attacker that has obtained local access through some means) would be able to discover the password by listing processes and their arguments. NOTE: the vendor states "This is not a vulnerability of H2 Console ... Passwords should never be passed on the command line and every qualified DBA or system administrator is expected to know that."
    </details>
  
    ### ✅ Precheck - Run tests
    - [[View Log]](logs\4.3.precheck-runTests.log)
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Test result
    | Total | Passed | Failed | Skipped | Errors |
    |-------|--------|--------|---------|--------|
    | 1 | 1 | 0 | 0 | 0 |
    </details>
  </details>

  ### ✅ Upgrade project to use `Spring Boot 3.3.x`, `Java 17`
  
  
  <details>
      <summary>[ click to toggle details ]</summary>
  
  - ###
    ### ✅ Upgrade using Agent
    - [[View Log]](logs\5.1.upgradeProjectUsingAgent.log)
    
    - 11 files changed, 15 insertions(+), 15 deletions(-)
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Code changes
    - Upgrade Spring Boot from 2.7.18 to 3.3.13
      - Updated parent POM version
    - Upgrade Java from 8 to 17
      - Updated java.version, maven.compiler.source, maven.compiler.target properties
    - Migrate javax.* to jakarta.* namespace
      - Changed javax.persistence imports to jakarta.persistence in Photo.java
      - Changed javax.validation imports to jakarta.validation in Photo.java
    - Update Oracle JDBC driver
      - Changed ojdbc8 to ojdbc11 for Java 17 compatibility
    - Apply Java 17 idioms via OpenRewrite
      - Replaced isPresent() checks with isEmpty() where applicable
      - Replaced String.format() with .formatted() method
      - Simplified @RequestParam annotation
    </details>
  
    ### ✅ Build Project
    - [[View Log]](logs\5.2.buildProject.log)
    
    - Build result: 100% Java files compiled
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Command
    `mvn clean test-compile -q -B -fn`
    </details>
  </details>

  ### ✅ Upgrade project to use `Spring Boot 3.4.x`
  
  
  <details>
      <summary>[ click to toggle details ]</summary>
  
  - ###
    ### ✅ Upgrade using Agent
    - [[View Log]](logs\6.1.upgradeProjectUsingAgent.log)
    
    - 10 files changed, 1 insertion(+), 781 deletions(-)
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Code changes
    - Upgrade Spring Boot from 3.3.13 to 3.4.4
      - Updated parent POM version from 3.3.13 to 3.4.4
    </details>
  
    ### ✅ Build Project
    - [[View Log]](logs\6.2.buildProject.log)
    
    - Build result: 100% Java files compiled
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Command
    `mvn clean test-compile -q -B -fn`
    </details>
  </details>

  ### ✅ Validate & Fix
  
  
  <details>
      <summary>[ click to toggle details ]</summary>
  
  - ###
    ### ✅ Validate CVEs
    - [[View Log]](logs\7.1.validateCves.log)
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Checked Dependencies
      - com.oracle.database.jdbc:ojdbc11:23.5.0.24.07:jar
      - org.springframework.boot:spring-boot-starter-web:3.4.4:jar
      - org.springframework.boot:spring-boot-starter-thymeleaf:3.4.4:jar
      - org.springframework.boot:spring-boot-starter-data-jpa:3.4.4:jar
      - org.springframework.boot:spring-boot-starter-validation:3.4.4:jar
      - org.springframework.boot:spring-boot-starter-json:3.4.4:jar
      - org.springframework.boot:spring-boot-starter-test:3.4.4:jar
      - com.h2database:h2:2.3.232:jar
      - org.springframework.boot:spring-boot-devtools:3.4.4:jar
      - java:*:17
    </details>
  
    ### ✅ Validate And Fix Code Behavior Changes
    - [[View Log]](logs\7.2.validateBehaviorChanges.log)
    
    - 11 files changed, 0 insertions(+), 0 deletions(-)
  
    ### ✅ Run Tests
    - [[View Log]](logs\7.3.runTests.log)
    
    <details>
        <summary>[ click to toggle details ]</summary>
    
    #### Test result
    | Total | Passed | Failed | Skipped | Errors |
    |-------|--------|--------|---------|--------|
    | 1 | 1 | 0 | 0 | 0 |
    </details>
  </details>

  ### ✅ Summarize Upgrade
  - [[View Log]](logs\8.summarizeUpgrade.log)