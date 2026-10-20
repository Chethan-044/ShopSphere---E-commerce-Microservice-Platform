FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY shipping-service/target/shipping-service-1.0-SNAPSHOT.jar app.jar
EXPOSE 8086
ENTRYPOINT ["java", "-jar", "app.jar"]
