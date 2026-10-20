FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY product-service/target/product-service-1.0-SNAPSHOT.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
