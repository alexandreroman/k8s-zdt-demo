FROM maven:3.6-jdk-8-alpine as maven
WORKDIR /home
COPY . .
RUN mvn package

FROM adoptopenjdk:11-jre-hotspot
WORKDIR /app
COPY --from=maven /home/target/*.jar ./
RUN addgroup --gid 1001 appuser && \
    adduser --system --uid 1001 --gid 1001 --no-create-home --disabled-login --disabled-password appuser
USER appuser

CMD ["java", "-jar", "./k8s-zdt-demo.jar"]
