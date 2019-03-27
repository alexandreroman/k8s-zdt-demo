FROM maven:3.6-jdk-8-alpine as maven
WORKDIR /home
COPY . .
RUN mvn package

FROM openjdk:8-jre-alpine
WORKDIR /app
COPY --from=maven /home/target/*.jar ./
RUN addgroup -g 1001 -S appuser && \
    adduser -u 1001 -G appuser -S appuser appuser
USER appuser

ENTRYPOINT ["java", "-jar", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "./k8s-zdt-demo.jar"]
