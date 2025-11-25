FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY target/java-cicd-demo-*-jar-with-dependencies.jar app.jar
CMD ["java","-jar","/app/app.jar"]