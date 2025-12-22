FROM eclipse-temurin:17-jre-alpine
EXPOSE 8080
COPY ./target/java-cicd-demo-*-jar-with-dependencies.jar /usr/app/
WORKDIR /usr/app
CMD java -jar java-cicd-demo-*-jar-with-dependencies.jar
