# AWS EC2 Automated Deployment with SSM

## Overview

This phase extends the existing AWS ECR CI/CD pipeline by automatically deploying the latest Docker image from Amazon ECR to an Amazon EC2 instance.

The deployment uses AWS Systems Manager (SSM), so GitHub Actions can deploy to EC2 without manually logging into the server.

---

## Architecture

```text
Developer
   |
   | git push to main
   v
GitHub
   |
   v
GitHub Actions
   |
   | Compile
   | Test
   | Package
   | Docker Build
   v
Amazon ECR
   |
   | SSM SendCommand
   v
Amazon EC2
   |
   | Pull latest Docker image
   | Stop old container
   | Remove old container
   | Start new container
   v
Spring Boot Application
Port 8080
```

---

## AWS Resources

### EC2

- Operating System: Amazon Linux 2023
- Instance Type: t3.micro
- Application Port: 8080
- Docker installed on EC2
- SSM Agent running

### Amazon ECR

Repository:

```text
copilot-jira-demo
```

ECR image:

```text
074494041026.dkr.ecr.eu-north-1.amazonaws.com/copilot-jira-demo
```

Region:

```text
eu-north-1
```

---

## IAM Roles

Two different IAM roles are used.

### GitHubActionsECRRole

Used by GitHub Actions through AWS OIDC.

Responsibilities:

- Authenticate GitHub Actions with AWS
- Push Docker images to Amazon ECR
- Send deployment commands through AWS Systems Manager
- Read the SSM command execution result

No long-term AWS access key is required by the GitHub Actions workflow.

### EC2ECRRole

Attached to the EC2 instance.

Responsibilities:

- Allow EC2 to pull images from Amazon ECR
- Allow EC2 to communicate with AWS Systems Manager
- Support CloudWatch Agent permissions

Policies used include:

```text
AmazonEC2ContainerRegistryReadOnly
AmazonSSMManagedInstanceCore
CloudWatchAgentServerPolicy
```

---

## Verify EC2 IAM Role

From the EC2 instance:

```bash
aws sts get-caller-identity
```

The instance successfully assumed:

```text
EC2ECRRole
```

---

## Verify SSM Agent

```bash
sudo systemctl status amazon-ssm-agent
```

Expected:

```text
Active: active (running)
```

The instance was also confirmed as:

```text
Ping status: Online
Session Manager connection status: Connected
```

This allows administration through AWS Systems Manager Session Manager instead of relying on SSH.

---

## Docker Setup

Verify Docker:

```bash
docker --version
```

Docker was successfully installed and running on the EC2 instance.

Verify images:

```bash
sudo docker images
```

Verify running containers:

```bash
sudo docker ps
```

---

## Application Container

The application runs using:

```text
Container name: copilot-jira-demo
Container port: 8080
EC2 port: 8080
```

Docker port mapping:

```text
0.0.0.0:8080 -> 8080/tcp
```

---

## Deployment Process

After a successful Docker image push to Amazon ECR, GitHub Actions sends an SSM command to EC2.

The EC2 deployment performs the following operations:

```bash
aws ecr get-login-password
docker login
docker pull
docker stop
docker rm
docker run
```

The old application container is therefore replaced by a container created from the latest ECR image.

---

## GitHub Actions Deployment Step

The ECR workflow contains an additional deployment step:

```yaml
- name: Deploy latest image to EC2 using SSM
  run: |
    COMMAND_ID=$(aws ssm send-command \
      --instance-ids "i-017359d0cc78c39c7" \
      --document-name "AWS-RunShellScript" \
      --comment "Deploy GitHub commit ${{ github.sha }}" \
      --parameters 'commands=[
        "aws ecr get-login-password --region eu-north-1 | sudo docker login --username AWS --password-stdin 074494041026.dkr.ecr.eu-north-1.amazonaws.com",
        "sudo docker pull 074494041026.dkr.ecr.eu-north-1.amazonaws.com/copilot-jira-demo:latest",
        "sudo docker stop copilot-jira-demo || true",
        "sudo docker rm copilot-jira-demo || true",
        "sudo docker run -d --name copilot-jira-demo --restart unless-stopped -p 8080:8080 074494041026.dkr.ecr.eu-north-1.amazonaws.com/copilot-jira-demo:latest"
      ]' \
      --query "Command.CommandId" \
      --output text)

    aws ssm wait command-executed \
      --command-id "$COMMAND_ID" \
      --instance-id "i-017359d0cc78c39c7"

    aws ssm get-command-invocation \
      --command-id "$COMMAND_ID" \
      --instance-id "i-017359d0cc78c39c7"
```

---

## Final CI/CD Flow

```text
git push main
      |
      v
GitHub Actions
      |
      +--> Compile
      |
      +--> Automated Tests
      |
      +--> Package
      |
      +--> Docker Build
      |
      v
Amazon ECR
      |
      v
SSM SendCommand
      |
      v
Amazon EC2
      |
      +--> ECR Login
      |
      +--> Pull Image
      |
      +--> Stop Old Container
      |
      +--> Remove Old Container
      |
      +--> Start New Container
      |
      v
Application running on port 8080
```

---

## Deployment Verification

Before automated deployment, the running container ID was:

```text
a816035a9fee
```

After a new commit triggered the CI/CD pipeline, EC2 showed:

```text
46811bf80bd8
```

The new container was created automatically by the deployment pipeline.

This verified the complete flow:

```text
Git Push
→ GitHub Actions
→ Amazon ECR
→ AWS Systems Manager
→ Amazon EC2
→ Docker Container
```

---

## Troubleshooting

### EC2 Instance Connect Failed

Initial browser-based SSH connection failed.

The EC2 security group and connectivity were checked, and the instance was later successfully accessed.

SSM Session Manager was also configured and verified as connected.

### Application returned 404 at /

The Spring Boot application was running correctly, but no controller was mapped to:

```text
/
```

The application controller uses:

```text
/users
```

Therefore the root URL returned the Spring Boot Whitelabel 404 page while the application itself remained healthy.

### HTTPS request sent to HTTP port

Tomcat logs showed invalid HTTP request-header messages when HTTPS traffic reached port 8080.

The application currently serves HTTP on:

```text
8080
```

---

## Result

The project now supports automatic AWS deployment.

A developer only needs to push code to the `main` branch.

GitHub Actions automatically:

1. Compiles the application.
2. Runs automated tests.
3. Packages the application.
4. Builds the Docker image.
5. Pushes the image to Amazon ECR.
6. Sends an AWS SSM deployment command.
7. EC2 pulls the latest image.
8. The old container is replaced.
9. The new application version starts automatically.

No manual EC2 deployment is required for the normal CI/CD process.New-Item AWS-EC2-DEPLOYMENT.md