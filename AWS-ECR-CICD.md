# AWS ECR CI/CD Pipeline with GitHub Actions

## Overview

This document covers the AWS ECR phase of the `copilot-jira-workflow-demo` project.

The previous phase already implemented:

```text
Developer
    ↓
GitHub
    ↓
GitHub Actions
    ↓
Compile
    ↓
Automated Tests
    ↓
Package
    ↓
Docker Build
    ↓
Docker Hub
```

The goal of this phase was to extend the project so that a successful GitHub Actions pipeline can also build and push a Docker image to **Amazon Elastic Container Registry (ECR)**.

Final AWS flow:

```text
Developer
    ↓
git push → main
    ↓
GitHub Actions
    ↓
Compile
    ↓
Automated Tests
    ↓
Package JAR
    ↓
GitHub OIDC
    ↓
AWS STS
    ↓
IAM Role
    ↓
Amazon ECR Login
    ↓
Docker Build
    ↓
Docker Push
    ↓
Amazon ECR
```

---

# 1. AWS Configuration

AWS Region used:

```text
Europe (Stockholm)
eu-north-1
```

The same region is used for the ECR repository and GitHub Actions configuration.

---

# 2. Amazon ECR Repository

An Amazon Elastic Container Registry repository was created.

Repository name:

```text
copilot-jira-demo
```

Repository type:

```text
Private
```

Image tag mutability:

```text
Mutable
```

Encryption:

```text
AES-256
```

Initially the repository contained:

```text
0 images
```

The objective was to automatically populate this repository from GitHub Actions.

---

# 3. Why Amazon ECR?

Docker Hub was already being used by the project.

Amazon ECR provides an AWS-hosted private container registry.

The new architecture became:

```text
                    GitHub
                       ↓
                 GitHub Actions
                       ↓
                 Tests + Package
                       ↓
                  Docker Build
                    ↙       ↘
             Docker Hub    Amazon ECR
```

For learning purposes, Docker Hub and ECR were implemented using separate GitHub Actions workflows.

---

# 4. GitHub OIDC Authentication

Permanent AWS access keys were not stored in GitHub.

Instead, GitHub Actions authenticates with AWS using **OpenID Connect (OIDC)**.

Authentication architecture:

```text
GitHub Actions
      ↓
GitHub OIDC Token
      ↓
AWS IAM OIDC Provider
      ↓
AWS STS
      ↓
Temporary AWS Credentials
      ↓
IAM Role
      ↓
Amazon ECR
```

This means GitHub can access AWS using temporary credentials rather than a permanent AWS access key and secret key.

---

# 5. Create GitHub OIDC Provider in AWS

In AWS:

```text
IAM
 ↓
Identity providers
 ↓
Add provider
```

Provider type:

```text
OpenID Connect
```

Provider URL:

```text
https://token.actions.githubusercontent.com
```

Audience:

```text
sts.amazonaws.com
```

The provider allows AWS IAM to trust identity tokens issued by GitHub Actions.

---

# 6. Create IAM Role

An IAM role was created for GitHub Actions.

Role name:

```text
GitHubActionsECRRole
```

Description:

```text
Allows GitHub Actions to push Docker images to Amazon ECR
```

The role uses:

```text
sts:AssumeRoleWithWebIdentity
```

This allows GitHub Actions to assume the role through OIDC.

---

# 7. ECR Permission

The following AWS managed policy was attached to the role:

```text
AmazonEC2ContainerRegistryPowerUser
```

This provides the permissions required for the CI/CD demonstration to interact with Amazon ECR.

The role is used only after GitHub successfully authenticates through OIDC.

---

# 8. GitHub Repository Trust

The role was configured to trust the GitHub repository:

```text
AnilkumarDave/copilot-jira-workflow-demo
```

Branch:

```text
main
```

During initial configuration, AWS generated a trust condition based on the traditional GitHub OIDC subject format.

The initial subject looked like:

```text
repo:AnilkumarDave/copilot-jira-workflow-demo:ref:refs/heads/main
```

This later caused an authentication problem because this GitHub repository was using an immutable OIDC subject format.

---

# 9. Separate GitHub Actions Workflow

The existing Docker Hub pipeline was intentionally left unchanged.

A new workflow was created:

```text
.github/workflows/ecr-cicd.yml
```

The project therefore contains:

```text
.github/workflows/

├── ci-cd.yml
│   └── Java → Tests → Package → Docker Hub
│
└── ecr-cicd.yml
    └── Java → Tests → Package → AWS ECR
```

This separation makes the Docker Hub and AWS ECR learning flows easier to understand.

---

# 10. AWS ECR Workflow

The final `ecr-cicd.yml` is:

```yaml
name: AWS ECR CI/CD Pipeline

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  build-and-push-ecr:
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

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::074494041026:role/GitHubActionsECRRole
          aws-region: eu-north-1

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push Docker image to Amazon ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: copilot-jira-demo
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

---

# 11. Workflow Trigger

The workflow runs automatically whenever code is pushed to:

```text
main
```

It can also be started manually because the workflow contains:

```yaml
workflow_dispatch:
```

The resulting process is:

```text
git push origin main
        ↓
AWS ECR CI/CD Pipeline
        ↓
Ubuntu GitHub Runner
```

---

# 12. GitHub OIDC Permissions

The workflow contains:

```yaml
permissions:
  id-token: write
  contents: read
```

`contents: read` allows GitHub Actions to check out the repository.

`id-token: write` allows the workflow to request a GitHub OIDC token.

That token is then used when assuming the AWS IAM role.

---

# 13. Compile and Test Before Docker Build

The application is compiled first:

```yaml
- name: Compile application
  run: ./mvnw clean compile
```

Automated tests then run:

```yaml
- name: Run automated tests
  run: ./mvnw test
```

The intended quality gate is:

```text
Compile
   ↓
Tests
   ↓
Tests Green?
  ↙     ↘
NO      YES
↓        ↓
FAIL   Continue
         ↓
      Package
         ↓
      Docker
```

If compilation or tests fail, later normal GitHub Actions steps do not execute.

Therefore a failed test prevents the workflow from continuing to the Docker/ECR publishing stage.

---

# 14. Package Application

After the tests pass:

```yaml
- name: Package application
  run: ./mvnw package -DskipTests
```

The Spring Boot JAR is created in:

```text
target/
```

The tests are skipped during this particular package command because they were already executed explicitly in the previous workflow step.

---

# 15. AWS Authentication Step

GitHub Actions authenticates with AWS using:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v5
  with:
    role-to-assume: arn:aws:iam::074494041026:role/GitHubActionsECRRole
    aws-region: eu-north-1
```

Conceptually:

```text
GitHub Actions
      ↓
OIDC Token
      ↓
AWS STS
      ↓
Assume GitHubActionsECRRole
      ↓
Temporary AWS Credentials
```

No permanent AWS access key or secret access key was added to this workflow.

---

# 16. Login to Amazon ECR

After AWS authentication succeeds:

```yaml
- name: Login to Amazon ECR
  id: login-ecr
  uses: aws-actions/amazon-ecr-login@v2
```

The login action exposes the ECR registry as:

```text
steps.login-ecr.outputs.registry
```

The Docker build step can then dynamically use the correct AWS ECR registry.

---

# 17. Build Docker Image

The Docker image is actually created here:

```bash
docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
```

The values are:

```text
ECR_REPOSITORY = copilot-jira-demo
IMAGE_TAG       = GitHub commit SHA
```

Therefore every successful pipeline can associate an image with the Git commit that produced it.

---

# 18. Docker Image Tags

Two tags are pushed.

## Git Commit SHA

The workflow uses:

```yaml
IMAGE_TAG: ${{ github.sha }}
```

Example:

```text
8d35473a1c08a1a222c55db4a6403ae4908c99cb
```

This provides traceability:

```text
Docker Image
     ↓
Git Commit SHA
     ↓
Exact Source Code
```

## Latest

The same image is also tagged:

```text
latest
```

Using:

```bash
docker tag \
$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
$ECR_REGISTRY/$ECR_REPOSITORY:latest
```

Therefore ECR contains both:

```text
copilot-jira-demo:<commit-sha>

copilot-jira-demo:latest
```

---

# 19. Push Docker Image to ECR

The workflow pushes both tags:

```bash
docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
```

Final flow:

```text
Dockerfile
    ↓
docker build
    ↓
Docker Image
    ↓
SHA Tag
    +
latest Tag
    ↓
docker push
    ↓
Amazon ECR
```

---

# 20. First Pipeline Failure

The first AWS ECR workflow did not succeed.

The pipeline reached:

```text
Configure AWS credentials
```

and failed with:

```text
Error: Could not assume role with OIDC:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

This was an important troubleshooting step because:

```text
Java setup       ✅
Compile          ✅
Tests            ✅
Package          ✅

AWS OIDC         ❌
ECR Login        NOT RUN
Docker Build     NOT RUN
ECR Push         NOT RUN
```

The problem was therefore isolated to AWS authentication rather than the application, tests, Maven or Docker.

---

# 21. OIDC Investigation

The AWS OIDC provider was checked.

Provider:

```text
token.actions.githubusercontent.com
```

Audience:

```text
sts.amazonaws.com
```

Both were correct.

The investigation then moved to the GitHub repository's OIDC configuration.

Path:

```text
GitHub Repository
    ↓
Settings
    ↓
Actions
    ↓
OIDC
```

GitHub showed an immutable subject claim prefix.

For this repository it included immutable owner and repository identifiers.

This did not match the original AWS IAM trust condition.

---

# 22. Original Trust Condition

The original AWS trust policy expected:

```text
repo:AnilkumarDave/copilot-jira-workflow-demo:ref:refs/heads/main
```

The policy also contained the same subject twice.

Because the OIDC subject presented by GitHub did not match the condition expected by AWS, STS rejected the request.

Result:

```text
GitHub OIDC Token
       ↓
Subject does not match AWS trust policy
       ↓
AWS STS rejects AssumeRoleWithWebIdentity
```

---

# 23. Corrected IAM Trust Policy

The trust policy was updated to match the immutable GitHub OIDC subject for the repository and `main` branch.

The final structure used:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::074494041026:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:AnilkumarDave@241099533/copilot-jira-workflow-demo@1366567861:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

This restricted the role to:

```text
Correct GitHub OIDC provider
        +
Correct AWS STS audience
        +
Correct immutable repository identity
        +
main branch
```

After updating the trust relationship, the failed GitHub Actions job was rerun.

---

# 24. Successful OIDC Authentication

After correcting the trust policy:

```text
Configure AWS credentials    ✅
Login to Amazon ECR          ✅
Build Docker image           ✅
Push Docker image            ✅
```

This proved:

```text
GitHub Actions
      ↓
GitHub OIDC
      ↓
AWS STS
      ↓
GitHubActionsECRRole
      ↓
Temporary AWS Credentials
      ↓
Amazon ECR
```

was functioning correctly.

---

# 25. Amazon ECR Verification

The `copilot-jira-demo` ECR repository initially contained:

```text
0 images
```

After the successful GitHub Actions run, ECR contained the Docker image.

The image had both:

```text
latest
```

and a Git commit SHA tag.

Example SHA:

```text
8d35473a1c08a1a222c55db4a6403ae4908c99cb
```

Observed image size:

```text
132.61 MB
```

This confirmed that GitHub Actions had successfully built and uploaded the application container to AWS.

---

# 26. Test With Another Developer Commit

After the first successful ECR push, another application change was made.

The change was committed and pushed to:

```text
main
```

This triggered both GitHub Actions workflows automatically.

```text
                    Developer Push
                          ↓
                       GitHub
                          ↓
               GitHub Actions Trigger
                   ↙             ↘
                  ↓               ↓
        CI/CD Pipeline      AWS ECR CI/CD Pipeline
                  ↓               ↓
              Tests             Tests
                  ↓               ↓
            Docker Build      Docker Build
                  ↓               ↓
             Docker Hub       Amazon ECR
```

Both workflows completed successfully.

This proved that the process was not a one-time manual deployment.

Every new push to `main` can automatically trigger both registry pipelines.

---

# 27. Current Two-Registry Architecture

The project currently uses two separate workflows.

```text
Developer
    ↓
git push → main
    ↓
GitHub
    ↓
    ├───────────────────────────────┐
    ↓                               ↓
CI/CD Pipeline             AWS ECR CI/CD Pipeline
    ↓                               ↓
Compile/Test                       Compile/Test
    ↓                               ↓
Package                            Package
    ↓                               ↓
Docker Build                       AWS OIDC
    ↓                               ↓
Docker Hub                        ECR Login
                                    ↓
                                Docker Build
                                    ↓
                                 Amazon ECR
```

Therefore the application image is currently built independently by each workflow.

This is intentional for the current learning phase because it keeps the Docker Hub and AWS ECR implementations easy to understand.

---

# 28. Current CI/CD Quality Gate

The important principle of the pipeline is:

```text
Developer Push
      ↓
Compile
      ↓
Automated Tests
      ↓
   PASS?
  ↙    ↘
NO      YES
↓        ↓
STOP   Package
         ↓
       Docker
         ↓
       Registry
```

A failed test should prevent a new application image from being published by that workflow.

---

# 29. Security Model

The AWS portion does not require storing:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

in the GitHub repository workflow.

Instead:

```text
GitHub
  ↓
OIDC
  ↓
AWS IAM
  ↓
STS
  ↓
Temporary Credentials
```

The IAM trust relationship restricts which GitHub identity can assume the AWS role.

---

# 30. Troubleshooting Summary

## Problem

```text
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

## Investigation

Checked:

```text
OIDC Provider     ✅
Audience          ✅
IAM Role          ✅
ECR Permission    ✅
GitHub Workflow   ✅
```

The mismatch was found in:

```text
GitHub OIDC subject
        vs
AWS IAM trust policy subject
```

## Fix

The AWS IAM trust policy was updated to match GitHub's immutable OIDC subject for the repository and `main` branch.

## Result

```text
OIDC Authentication    ✅
AWS STS                ✅
IAM Role               ✅
ECR Login              ✅
Docker Build           ✅
Docker Push            ✅
```

---

# 31. Final AWS ECR Architecture

```text
                    DEVELOPER
                        ↓
                  CODE CHANGE
                        ↓
                    GIT COMMIT
                        ↓
                     GIT PUSH
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
                  TESTS PASSED
                        ↓
                  PACKAGE JAR
                        ↓
                  GITHUB OIDC
                        ↓
                     AWS STS
                        ↓
              GitHubActionsECRRole
                        ↓
              TEMPORARY CREDENTIALS
                        ↓
                  LOGIN TO ECR
                        ↓
                  DOCKER BUILD
                        ↓
              ┌─────────┴─────────┐
              ↓                   ↓
         COMMIT SHA             LATEST
              ↓                   ↓
              └─────────┬─────────┘
                        ↓
                  AMAZON ECR
                        ↓
             copilot-jira-demo
```

---

# 32. Completed AWS ECR Phase

```text
AWS Account                         ✅
AWS Region Selection                ✅
Amazon ECR Repository               ✅
GitHub OIDC Provider                ✅
AWS IAM Role                        ✅
ECR PowerUser Permission            ✅
Repository Trust Configuration      ✅
Separate ECR GitHub Workflow        ✅
Java 21                             ✅
Compile                             ✅
Automated Tests                     ✅
Package                             ✅
OIDC Authentication                 ✅
AWS STS Temporary Credentials       ✅
Amazon ECR Login                    ✅
Docker Build                        ✅
Commit SHA Tag                      ✅
Latest Tag                          ✅
Docker Push to ECR                  ✅
ECR Image Verification              ✅
Second Developer Commit Test        ✅
Docker Hub Workflow                 ✅
ECR Workflow                        ✅
```

---

# 33. Next Phase

The ECR image is now successfully stored in AWS.

The next stage is deployment.

The learning path from the lecture continues toward running the container on AWS infrastructure:

```text
GitHub
   ↓
GitHub Actions
   ↓
Tests
   ↓
Docker
   ↓
Amazon ECR
   ↓
AWS Compute / Deployment
   ↓
Running Application
```

This deployment phase should be documented separately so that this file remains focused specifically on:

```text
GitHub Actions
      +
GitHub OIDC
      +
AWS IAM / STS
      +
Docker
      +
Amazon ECR
```