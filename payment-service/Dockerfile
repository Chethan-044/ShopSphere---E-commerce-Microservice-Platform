FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY payment-service/target/payment-service-1.0-SNAPSHOT.jar app.jar
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]
