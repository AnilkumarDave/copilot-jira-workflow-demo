FROM eclipse-temurin:21-jre

WORKDIR /app

COPY target/copilot-jira-workflow-demo-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]