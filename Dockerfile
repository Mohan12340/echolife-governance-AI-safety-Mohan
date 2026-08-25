# Stage 1: Build the application
FROM eclipse-temurin:17-jdk-jammy AS builder
WORKDIR /app

# Copy Maven files
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

RUN chmod +x ./mvnw
RUN ./mvnw dependency:go-offline -B

# Copy source and build JAR
COPY src ./src
RUN ./mvnw clean package -DskipTests

# Stage 2: Runtime image
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Create user/group, setup upload directory, and grant explicit ownership and read/write permissions
RUN addgroup --system echolife && adduser --system --group echolife && \
    mkdir -p /app/uploads && \
    chown -R echolife:echolife /app && \
    chmod -R 775 /app

# Copy the artifact ensuring echolife owns the file
COPY --chown=echolife:echolife --from=builder /app/target/*.jar app.jar

# Switch to the non-root user
USER echolife:echolife

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
