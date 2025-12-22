# Multi-stage build
FROM maven:3.8.4-openjdk-17-slim AS build
WORKDIR /app

# Copy pom.xml first for better caching
COPY pom.xml .
RUN mvn dependency:go-offline -q

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests -q

# Runtime stage
FROM openjdk:17-jre-alpine
WORKDIR /usr/app

# Copy the fat JAR from build stage
COPY --from=build /app/target/*-jar-with-dependencies.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]