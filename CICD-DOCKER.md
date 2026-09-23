# Docker + GitHub Actions CI/CD

## Overview

This document continues the CI/CD work from the main `README.md`.

The main README covers:

```text
Jira
  ↓
Atlassian Rovo MCP
  ↓
GitHub Copilot Cloud Agent
  ↓
Development + Automated Tests
  ↓
Human Review
  ↓
GitHub Actions
  ↓
Compile
  ↓
Test
  ↓
Package
```

This document extends that pipeline with Docker and Docker Hub:

```text
Code Change
    ↓
Git Push
    ↓
GitHub Actions
    ↓
Compile
    ↓
Automated Tests
    ↓
Package JAR
    ↓
Build Docker Image
    ↓
Push to Docker Hub
    ↓
Docker Pull
    ↓
Run Container
    ↓
Application
```

---

# 1. Dockerfile

A `Dockerfile` was created in the project root:

```dockerfile
FROM eclipse-temurin:21-jre

WORKDIR /app

COPY target/copilot-jira-workflow-demo-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
```

The Docker image contains:

```text
Java 21 Runtime
      +
Spring Boot JAR
      ↓
Runnable Docker Image
```

---

# 2. Package the Application

Before building the Docker image, the Spring Boot application was packaged:

```powershell
.\mvnw.cmd clean package
```

Result:

```text
Tests run: 3
Failures: 0
Errors: 0
Skipped: 0

BUILD SUCCESS
```

Generated JAR:

```text
target/copilot-jira-workflow-demo-0.0.1-SNAPSHOT.jar
```

---

# 3. Local Docker Build

The first Docker image was built locally:

```powershell
docker build -t copilot-jira-demo:1.0 .
```

Image:

```text
copilot-jira-demo:1.0
```

---

# 4. Run the Docker Container

The application was started using:

```powershell
docker run -d -p 8081:8080 --name copilot-jira-container copilot-jira-demo:1.0
```

Port mapping:

```text
Host Machine        Docker Container

8081        →        8080
```

The application inside the container listens on port `8080`.

Port `8081` was used on the host because another Docker application was already using host port `8080`.

---

# 5. Verify the Dockerized Application

Application endpoint:

```text
http://localhost:8081/users/
```

The user creation endpoint was also tested:

```powershell
Invoke-WebRequest `
  -Uri "http://localhost:8081/users" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"name":"Anil","email":"anil@example.com","password":"Test123"}'
```

Result:

```text
201 Created
User created successfully
```

This proved that the Spring Boot application was successfully running inside Docker.

---

# 6. Docker Hub Repository

Docker Hub username:

```text
anildave25
```

Docker image:

```text
anildave25/copilot-jira-demo:1.0
```

The local image was tagged for Docker Hub:

```powershell
docker tag copilot-jira-demo:1.0 anildave25/copilot-jira-demo:1.0
```

---

# 7. Manual Docker Hub Push

The image was initially pushed manually to understand the complete Docker lifecycle.

```powershell
docker login
```

Then:

```powershell
docker push anildave25/copilot-jira-demo:1.0
```

This created the following flow:

```text
Local Source Code
      ↓
Maven Package
      ↓
Docker Build
      ↓
Local Docker Image
      ↓
Docker Push
      ↓
Docker Hub
```

---

# 8. Prove the Image Can Be Distributed

After the image was pushed successfully, the local container and image were removed.

The image was then downloaded again from Docker Hub:

```powershell
docker pull anildave25/copilot-jira-demo:1.0
```

The downloaded image was started:

```powershell
docker run -d -p 8081:8080 --name copilot-jira-container anildave25/copilot-jira-demo:1.0
```

The application was successfully accessible again.

This demonstrated:

```text
Docker Hub
    ↓
docker pull
    ↓
Local Machine
    ↓
docker run
    ↓
Application Running
```

Another machine therefore does not need the project's source code, Maven or IntelliJ to run the packaged application.

It only needs Docker and access to the image.

---

# 9. Docker Hub Access Token

To automate Docker Hub authentication from GitHub Actions, a Docker Hub access token was created.

The token itself must never be committed to Git.

GitHub Repository Secrets were created:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

The secret values remain outside the repository.

---

# 10. GitHub Actions + Docker Hub

The existing GitHub Actions workflow was extended after:

```text
Compile
  ↓
Test
  ↓
Package
```

The new steps are:

```text
Login to Docker Hub
        ↓
Build Docker Image
        ↓
Push Docker Image
```

Docker Hub authentication:

```yaml
- name: Login to Docker Hub
  uses: docker/login-action@v4
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

Docker build and push:

```yaml
- name: Build and push Docker image
  uses: docker/build-push-action@v7
  with:
    context: .
    push: true
    tags: anildave25/copilot-jira-demo:1.0
```

---

# 11. Final CI/CD Workflow

The completed workflow is:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches:
      - main

  pull_request:
    branches:
      - main

  workflow_dispatch:

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v7

      - name: Set up Java 21
        uses: actions/setup-java@v6
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: 'maven'

      - name: Compile application
        run: ./mvnw clean compile

      - name: Run automated tests
        run: ./mvnw test

      - name: Package application
        run: ./mvnw package -DskipTests

      - name: Login to Docker Hub
        uses: docker/login-action@v4
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v7
        with:
          context: .
          push: true
          tags: anildave25/copilot-jira-demo:1.0
```

---

# 12. Automated CI/CD Flow

After Docker integration, the pipeline became:

```text
Developer
    ↓
Change Source Code
    ↓
git commit
    ↓
git push origin main
    ↓
GitHub Repository
    ↓
GitHub Actions Triggered
    ↓
Ubuntu Runner
    ↓
Checkout Repository
    ↓
Set Up Java 21
    ↓
Compile
    ↓
Run 3 Automated Tests
    ↓
Package Spring Boot JAR
    ↓
Login to Docker Hub
    ↓
Build Docker Image
    ↓
Push Docker Image
    ↓
Docker Hub
```

This removes the need to manually run:

```text
docker build
docker login
docker push
```

after every source-code change.

---

# 13. Version 2 End-to-End Proof

To prove that GitHub Actions was actually building a new Docker image, the application message was changed to:

```text
Copilot Jira CI/CD Docker Application Version 2 is running successfully!
```

The change was committed:

```text
Update application message to version 2
```

and pushed to `main`.

No manual Docker build or Docker push was performed.

GitHub Actions automatically completed:

```text
Checkout Repository             ✅
Set Up Java 21                  ✅
Compile Application             ✅
Run Automated Tests             ✅
Package Application             ✅
Login to Docker Hub             ✅
Build and Push Docker Image     ✅
```

---

# 14. Verify the Image Came From CI/CD

The old local image was removed.

Old image ID:

```text
3c6743eef860
```

The image was then pulled again:

```powershell
docker pull anildave25/copilot-jira-demo:1.0
```

Docker returned:

```text
Status: Downloaded newer image for anildave25/copilot-jira-demo:1.0
```

New image ID:

```text
d41adb031299
```

Docker Hub digest:

```text
sha256:d41adb031299d3c3896e77fc78e9e156fdf0e26209bfcfe82797076a743d15c0
```

The different image confirmed that the locally cached image had been replaced with the newer image from Docker Hub.

---

# 15. Run the CI/CD-Built Image

The new image was started:

```powershell
docker run -d -p 8081:8080 --name copilot-jira-container anildave25/copilot-jira-demo:1.0
```

The application was opened at:

```text
http://localhost:8081/users/
```

Result:

```text
Copilot Jira CI/CD Docker Application Version 2 is running successfully!
```

This proved the complete end-to-end pipeline:

```text
CODE CHANGE
     ↓
GIT COMMIT
     ↓
GIT PUSH
     ↓
GITHUB ACTIONS
     ↓
COMPILE
     ↓
AUTOMATED TESTS
     ↓
PACKAGE
     ↓
DOCKER BUILD
     ↓
DOCKER HUB PUSH
     ↓
DELETE OLD LOCAL IMAGE
     ↓
DOCKER PULL
     ↓
RUN CONTAINER
     ↓
VERSION 2 APPLICATION
```

---

# 16. Important Docker Commands

View images:

```powershell
docker images
```

View running containers:

```powershell
docker ps
```

View all containers:

```powershell
docker ps -a
```

View logs:

```powershell
docker logs copilot-jira-container
```

Stop container:

```powershell
docker stop copilot-jira-container
```

Remove container:

```powershell
docker rm copilot-jira-container
```

Remove image:

```powershell
docker rmi anildave25/copilot-jira-demo:1.0
```

Pull image:

```powershell
docker pull anildave25/copilot-jira-demo:1.0
```

Run image:

```powershell
docker run -d -p 8081:8080 --name copilot-jira-container anildave25/copilot-jira-demo:1.0
```

---

# 17. Troubleshooting

## JAVA_HOME Using Wrong Java Version

The project requires Java 21.

Check:

```powershell
java -version
.\mvnw.cmd -version
$env:JAVA_HOME
```

The terminal initially had Maven using Java 17 even though `java -version` showed Java 21.

The current terminal was corrected using:

```powershell
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-21.0.12.101-hotspot"
```

After this, Maven successfully used Java 21.

---

## Docker Image Architecture Error

Some external practice images were built for:

```text
ARM64
```

while the development machine used:

```text
AMD64 / x86_64
```

This produced errors such as:

```text
exec format error
```

This demonstrated that Docker image architecture must be compatible with the host or supported through appropriate emulation/multi-platform images.

---

## Port Already in Use

Another Docker application was already using host port `8080`.

Therefore this application used:

```text
8081:8080
```

Meaning:

```text
Host 8081 → Container 8080
```

Multiple containers can use port `8080` internally, but they cannot use the same host port simultaneously.

---

## 404 on Root URL

Opening:

```text
http://localhost:8081/
```

initially returned `404`.

The application was running correctly, but no controller mapping existed for `/`.

---

## 405 on /users

Opening:

```text
http://localhost:8081/users
```

in a browser initially resulted in `405 Method Not Allowed`.

The reason was that `/users` originally supported:

```text
POST
```

but the browser was sending:

```text
GET
```

A GET endpoint was later added for browser verification.

---

## Docker Desktop Not Running

A Docker command temporarily failed because the Docker Desktop Linux engine was unavailable.

Starting Docker Desktop restored access to the Docker daemon.

---

# 18. Final Result

The Docker phase is complete.

```text
Spring Boot Application          ✅
Java 21                          ✅
Maven Package                    ✅
Automated Tests                  ✅
Dockerfile                       ✅
Local Docker Build               ✅
Local Container                  ✅
Application Verification         ✅
Docker Hub Repository            ✅
Manual Docker Push               ✅
Manual Docker Pull               ✅
Docker Hub Access Token          ✅
GitHub Repository Secrets        ✅
GitHub Actions Docker Login      ✅
Automated Docker Build           ✅
Automated Docker Push            ✅
Version 2 CI/CD Verification     ✅
Fresh Docker Pull Verification   ✅
```

The final architecture is:

```text
SOURCE CODE
    ↓
GITHUB
    ↓
GITHUB ACTIONS
    ↓
JAVA 21
    ↓
COMPILE
    ↓
AUTOMATED TESTS
    ↓
PACKAGE
    ↓
DOCKER BUILD
    ↓
DOCKER HUB
    ↓
DOCKER PULL
    ↓
CONTAINER
    ↓
RUNNING APPLICATION
```

---

# Next Learning Phase

Advanced SDET CI/CD automation will be developed as a **separate project**.

That project can later cover:

```text
Scheduled Regression Tests
        ↓
Failed Test Detection
        ↓
Automatic Rerun
        ↓
Persistent Failure Analysis
        ↓
Test Reporting
        ↓
Optional Jira Defect Creation
        ↓
Human Review
```