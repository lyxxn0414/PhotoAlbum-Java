# ==============================================================================
# Stage 1: Build
# Multi-stage build using Maven 3.9.6 with Eclipse Temurin JDK 21
# ==============================================================================
FROM maven:3.9.6-eclipse-temurin-21 AS build

WORKDIR /app

# Copy Maven descriptor first (layer caching for dependency resolution)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build the application
COPY src ./src
RUN mvn clean package -DskipTests -B

# ==============================================================================
# Stage 2: Runtime
# Minimal Eclipse Temurin JRE 21 image for production
# ==============================================================================
FROM eclipse-temurin:21-jre

WORKDIR /app

# Install curl for health checks and create non-root user
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --system --gid 1001 appgroup && \
    useradd --system --uid 1001 --gid appgroup --no-create-home appuser

# Copy the built jar file from the build stage
COPY --from=build --chown=appuser:appgroup /app/target/photo-album-*.jar app.jar

# Expose the application port (Azure Container Apps ingress target port)
EXPOSE 8080

# Container-aware JVM settings for Azure Container Apps
# - MaxRAMPercentage: let JVM auto-size heap based on container memory limits
# - UseContainerSupport: ensure JVM respects cgroup memory/cpu constraints
# - UseG1GC: low-latency garbage collector suitable for containerized workloads
ENV JAVA_OPTS="-XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:InitialRAMPercentage=50.0 \
    -XX:+UseG1GC \
    -Djava.security.egd=file:/dev/./urandom \
    -Dserver.port=8080"

# Health check for container orchestration
# Azure Container Apps uses HTTP probes; this HEALTHCHECK supports local Docker/Compose usage
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health/liveness || exit 1

# Switch to non-root user
USER appuser

# Run the Spring Boot application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]