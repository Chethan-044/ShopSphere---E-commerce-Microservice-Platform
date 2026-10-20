FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY notification-service/target/notification-service-1.0-SNAPSHOT.jar app.jar
EXPOSE 8087
ENTRYPOINT ["java", "-jar", "app.jar"]
