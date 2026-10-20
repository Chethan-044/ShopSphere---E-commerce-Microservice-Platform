FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY review-service/target/review-service-1.0-SNAPSHOT.jar app.jar
EXPOSE 8088
ENTRYPOINT ["java", "-jar", "app.jar"]
