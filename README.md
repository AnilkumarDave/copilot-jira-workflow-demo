# GitHub Copilot + Jira + Atlassian Rovo MCP + CI/CD Workflow Demo

## Overview

This project demonstrates an end-to-end software development and automation workflow using:

- GitHub Copilot Cloud Agent
- Jira Cloud
- Atlassian Rovo MCP
- Java 21
- Spring Boot
- Maven
- Automated Testing
- GitHub Actions CI/CD
- Human Review and Approval

The project is divided into two main parts.

### Part 1 — AI-Assisted Development Workflow

GitHub Copilot Cloud Agent works with Jira Cloud through Atlassian Rovo MCP to retrieve a Jira User Story, implement the requirement, create/update tests, create a feature branch and Pull Request, and move the Jira issue through the development workflow.

Important approval actions remain under human control.

### Part 2 — Continuous Integration with GitHub Actions

GitHub Actions automatically builds and tests the application whenever code is pushed to `main` or a Pull Request targets `main`.

The CI pipeline:

- checks out the repository
- sets up Java 21
- compiles the application
- executes automated tests
- packages the application

---

# 1. Complete Architecture

```text
                    JIRA / DEVELOPMENT WORKFLOW

Jira User Story
      ↓
Atlassian Rovo MCP
      ↓
GitHub Copilot Cloud Agent
      ↓
Read Requirement
      ↓
Implement Code + Tests
      ↓
Feature Branch
      ↓
Pull Request
      ↓
Jira → In Review
      ↓
══════════════════════
     HUMAN CONTROL
══════════════════════
      ↓
Human Review
      ↓
Human Merge
      ↓
Jira → Done


                         CI WORKFLOW

Developer Push / Pull Request
      ↓
GitHub Repository
      ↓
GitHub Actions
      ↓
Ubuntu Runner
      ↓
Checkout Repository
      ↓
Set Up Java 21
      ↓
Compile Application
      ↓
Run Automated Tests
      ↓
Package Application
      ↓
BUILD SUCCESS
```

---

# 2. Technologies

- GitHub
- GitHub Copilot Cloud Agent
- GitHub Actions
- Jira Cloud
- Atlassian Rovo MCP V2
- Git
- Java 21
- Spring Boot
- Maven
- Maven Wrapper
- JUnit
- MockMvc
- YAML
- Ubuntu GitHub-hosted Runner

---

# 3. Important Concepts

## GitHub Copilot Agent

The Copilot Agent acts as the AI development worker.

It can:

- inspect the repository
- understand requirements
- modify code
- create/update tests
- run tests
- create branches
- commit changes
- push changes
- create Pull Requests

---

## MCP

MCP means:

```text
Model Context Protocol
```

MCP acts as a bridge between an AI agent and external systems.

In this project:

```text
GitHub Copilot
      ↓
Atlassian Rovo MCP
      ↓
Jira Cloud
```

This allows Copilot to interact with Jira instead of requiring the Jira requirement to be manually copied into the development prompt.

---

## CI/CD

CI/CD means:

```text
Continuous Integration
Continuous Delivery / Continuous Deployment
```

In this project, GitHub Actions provides the Continuous Integration workflow.

```text
Code Change
    ↓
Git Push
    ↓
GitHub Actions Trigger
    ↓
Temporary Ubuntu Runner
    ↓
Compile
    ↓
Automated Tests
    ↓
Package
    ↓
Result
```

The CI pipeline automatically verifies that changes can compile and pass the automated test suite.

---

## Human-in-the-Loop

AI performs development work, but important approval actions remain with a human.

```text
AI:

Requirement
    ↓
Code
    ↓
Tests
    ↓
Branch
    ↓
Pull Request
    ↓
In Review


Human:

Review
    ↓
Verify
    ↓
Merge
    ↓
Done
```

The agent must NOT automatically merge its own Pull Request or move the Jira story to Done.

---

# 4. Prerequisites

## GitHub

- GitHub repository
- GitHub Copilot with Cloud Agent capability
- Copilot Agent enabled
- Repository access
- Agent Secrets access
- MCP server configuration access
- GitHub Actions enabled

## Atlassian

- Jira Cloud site
- Jira project
- Atlassian Rovo MCP enabled
- API-token authentication enabled
- Jira read/search/write permissions

## Local Development

- Git
- Java 21
- Maven / Maven Wrapper
- IntelliJ IDEA or another IDE

---

# 5. Jira Setup

Demo Jira project:

```text
Copilot Automation Demo
```

Project key:

```text
CAD
```

Demo story:

```text
CAD-2
```

Requirement:

```text
Reject creating a user when password is empty
```

Acceptance Criteria:

```text
Given a user creation request
When the password field is empty
Then the API should reject the request
And return a validation error.
```

---

# 6. Jira Workflow

The workflow used for this demo is:

```text
To Do
  ↓
In Progress
  ↓
In Review
  ↓
Done
```

`In Review` was added so that the AI can stop before final human approval.

Responsibility:

```text
Copilot:

To Do
  ↓
In Progress
  ↓
In Review


Human:

In Review
  ↓
Done
```

This provides a human approval checkpoint.

---

# 7. Configure Atlassian Rovo MCP

In Atlassian Administration, configure the Rovo MCP server.

Enable:

```text
API token authentication
```

Ensure the required capabilities are available:

```text
READ
SEARCH
WRITE
```

Delete/manage permissions are not required for this demo.

---

# 8. Create Scoped Atlassian API Token

Create an Atlassian API token with scopes for:

```text
Rovo MCP V2
```

Jira scopes used in this demo:

```text
read:jira:agent-interface

search:jira:agent-interface

write:jira:agent-interface
```

Never put the API token into source code or commit it to Git.

---

# 9. Prepare Authentication

For API-token authentication:

```text
ATLASSIAN_EMAIL:ATLASSIAN_API_TOKEN
```

is Base64 encoded.

PowerShell example:

```powershell
$pair = "YOUR_ATLASSIAN_EMAIL:YOUR_API_TOKEN"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
[Convert]::ToBase64String($bytes)
```

Important:

> Base64 is encoding, not encryption.

The Base64 value must therefore also be treated as a secret.

---

# 10. GitHub Agent Secret

Store the Base64 authentication value as a GitHub **Agent Secret**.

Secret name used in this project:

```text
COPILOT_MCP_ROVO_AUTH
```

Conceptually:

```text
Copilot Cloud Agent
        ↓
GitHub Agent Secret
        ↓
Rovo MCP
        ↓
Jira
```

Never store the actual secret value in this README or source repository.

---

# 11. Configure Rovo MCP in GitHub

Configure the MCP server in the repository's GitHub Copilot settings.

Rovo MCP V2 endpoint:

```text
https://mcp.atlassian.com/v2/mcp
```

The configuration connects:

```text
GitHub Copilot Cloud Agent
        ↓
COPILOT_MCP_ROVO_AUTH
        ↓
Atlassian Rovo MCP V2
        ↓
Jira
```

The GitHub Cloud Agent MCP configuration is separate from IntelliJ/IDE MCP configuration.

Therefore, configuring MCP in GitHub does not automatically configure the same MCP server inside IntelliJ.

---

# 12. Test MCP Before Automation

Before allowing AI to modify anything, perform a read-only diagnostic.

Example task:

```text
Using the configured Atlassian Rovo MCP server,
retrieve Jira issue CAD-2.

Report:
- issue key
- summary
- current status
- description
- acceptance criteria

Do not modify Jira.
Do not modify source code.
```

Expected result:

```text
CAD-2 successfully retrieved
Status: To Do
Description: retrieved
Acceptance Criteria: retrieved
```

This proves:

```text
GitHub Copilot
      ↓
Rovo MCP
      ↓
Jira
      ↓
READ SUCCESS
```

Always verify MCP connectivity before building larger automation.

---

# 13. Baseline Application

The repository contains a small Spring Boot application.

Before CAD-2 was implemented, the API intentionally accepted:

```json
{
  "name": "Anil",
  "email": "anil@example.com",
  "password": ""
}
```

and returned:

```text
201 Created
```

This deliberately incorrect behaviour created a real requirement for Copilot to implement.

---

# 14. Copilot Agent Instructions

The agent was instructed to:

```text
Work on Jira issue CAD-2 using Atlassian Rovo MCP.

1. Retrieve CAD-2 from Jira.

2. Read its description, acceptance criteria and status.

3. Continue only when status is "To Do".

4. Before modifying source code:
   transition To Do → In Progress.

5. Inspect the existing repository.

6. Implement only the Jira acceptance criteria.

7. Add/update automated tests.

8. Run the complete Maven test suite.

9. Do NOT commit directly to main.

10. Create a feature branch.

11. Commit and push the implementation.

12. Create a Pull Request targeting main.

13. After the PR is successfully created:
    transition In Progress → In Review.

14. Do NOT merge the Pull Request.

15. Do NOT transition Jira to Done.

A human must review and merge the Pull Request.
```

These rules prevent the AI from completing the entire lifecycle without human approval.

---

# 15. What Copilot Did

For CAD-2, Copilot:

```text
Read CAD-2
     ↓
Moved CAD-2 → In Progress
     ↓
Inspected Repository
     ↓
Implemented Password Validation
     ↓
Updated Automated Tests
     ↓
Ran Tests
     ↓
Created Feature Branch
     ↓
Committed Changes
     ↓
Pushed Branch
     ↓
Created PR #1
     ↓
Moved CAD-2 → In Review
```

Feature branch:

```text
copilot/cad-2-user-creation-validation
```

Pull Request:

```text
PR #1
CAD-2 Reject empty passwords in user creation
```

---

# 16. Implementation Result

Copilot added validation so that an empty password is rejected.

Conceptually:

```text
POST /users
     ↓
Validate Request
     ↓
Password empty?
    /          \
  YES          NO
   ↓            ↓
 400           201
Validation    Created
Error
```

Automated tests cover:

```text
Empty password → 400 Bad Request

Valid password → 201 Created
```

---

# 17. Verify the AI's Work

An AI-generated Pull Request should be independently verified.

The feature branch was checked locally:

```powershell
git fetch origin
git switch --track origin/copilot/cad-2-user-creation-validation
```

The complete test suite was run:

```powershell
.\mvnw.cmd test
```

Result:

```text
Tests run: 3
Failures: 0
Errors: 0
Skipped: 0

BUILD SUCCESS
```

This independently verified the Copilot implementation.

---

# 18. Human Review and Merge

After verification:

```text
Copilot PR
    ↓
Human Reviews Code
    ↓
Human Verifies Acceptance Criteria
    ↓
Human Runs Tests
    ↓
Human Marks PR Ready
    ↓
Human Merges PR
```

Copilot was NOT allowed to merge its own PR.

After the successful human merge:

```text
CAD-2

In Review
    ↓
Done
```

was performed manually.

---

# 19. GitHub Actions CI/CD

After completing the Jira + Copilot development workflow, GitHub Actions was added to provide Continuous Integration.

Workflow file:

```text
.github/workflows/ci-cd.yml
```

The workflow is designed to verify the application automatically whenever relevant repository changes occur.

---

# 20. CI/CD Triggers

The workflow supports three triggers.

## Push to Main

```yaml
push:
  branches:
    - main
```

When code is pushed to `main`, GitHub Actions automatically starts the pipeline.

## Pull Request to Main

```yaml
pull_request:
  branches:
    - main
```

A Pull Request targeting `main` can trigger the CI pipeline so changes can be validated before merge.

## Manual Trigger

```yaml
workflow_dispatch:
```

This allows the workflow to be manually started from GitHub Actions.

Conceptually:

```text
Push to main
       \
Pull Request → GitHub Actions
       /
Manual Run
```

---

# 21. CI/CD Job

The workflow contains the following job:

```yaml
jobs:
  build-and-test:
    runs-on: ubuntu-latest
```

GitHub creates a temporary Ubuntu runner for the job.

The application does not depend on the developer's local machine for CI execution.

---

# 22. CI/CD Pipeline Steps

The pipeline performs:

```text
Start Ubuntu Runner
        ↓
Checkout Repository
        ↓
Set Up Java 21
        ↓
Restore/Use Maven Cache
        ↓
Compile Application
        ↓
Run Automated Tests
        ↓
Package Application
        ↓
Complete Job
```

---

# 23. Checkout Repository

The first important pipeline step retrieves the repository:

```yaml
- name: Checkout repository
  uses: actions/checkout@v7
```

The GitHub-hosted runner is temporary, so the repository must first be checked out into the runner environment.

---

# 24. Java Configuration

The pipeline configures Java 21:

```yaml
- name: Set up Java 21
  uses: actions/setup-java@v6
  with:
    java-version: '21'
    distribution: 'temurin'
    cache: 'maven'
```

This ensures that CI uses the Java version required by the project.

Maven caching is also enabled to improve dependency handling between workflow runs.

---

# 25. Compile Application

Compilation is performed using:

```yaml
- name: Compile application
  run: ./mvnw clean compile
```

If compilation fails, the pipeline stops and reports the failure.

---

# 26. Run Automated Tests

Automated tests are executed using:

```yaml
- name: Run automated tests
  run: ./mvnw test
```

Successful CI result:

```text
Tests run: 3
Failures: 0
Errors: 0
Skipped: 0

BUILD SUCCESS
```

This means all three automated tests passed inside the GitHub-hosted Ubuntu environment.

---

# 27. Package Application

After successful testing, the application is packaged:

```yaml
- name: Package application
  run: ./mvnw package -DskipTests
```

Tests are skipped during this particular packaging command because they were already executed in the previous pipeline step.

The resulting flow is:

```text
Compile
   ↓
Test
   ↓
Package
```

---

# 28. Final GitHub Actions Workflow

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
```

---

# 29. Real CI Failure Encountered

The first GitHub Actions run failed during compilation.

Error:

```text
./mvnw: Permission denied

Process completed with exit code 126
```

The project was being developed on Windows, while GitHub Actions was running the workflow on Ubuntu.

The Maven Wrapper file did not have executable permission in Git.

---

# 30. Maven Wrapper Permission Fix

The problem was fixed using:

```powershell
git update-index --chmod=+x mvnw
```

The Git file mode changed from:

```text
100644
```

to:

```text
100755
```

Conceptually:

```text
100644
Normal file
   ↓
Add executable permission
   ↓
100755
Executable file
```

After committing and pushing the permission change, GitHub Actions automatically started another pipeline.

The second pipeline completed successfully.

This demonstrates an important CI concept:

> Code that works in a Windows development environment may encounter environment-specific issues when executed on a Linux CI runner.

---

# 31. GitHub Actions Version Update

The workflow was subsequently updated to use:

```text
actions/checkout@v7
actions/setup-java@v6
```

This removed the previous action/runtime deprecation warnings observed during the earlier pipeline run.

After the update, another push to `main` automatically started the CI pipeline.

Result:

```text
CI/CD Pipeline #3

Status: SUCCESS
Branch: main
Tests: PASS
Package: PASS
Warnings: none
```

---

# 32. CI/CD Result

The final CI workflow successfully performs:

```text
Developer
    ↓
git push origin main
    ↓
GitHub
    ↓
GitHub Actions Trigger
    ↓
Ubuntu Runner
    ↓
Checkout
    ↓
Java 21
    ↓
Compile
    ↓
3 Automated Tests
    ↓
Package
    ↓
BUILD SUCCESS
```

This means application verification is no longer dependent only on manually running tests from IntelliJ.

---

# 33. Complete End-to-End Project Result

The repository now demonstrates two connected automation workflows.

## Development Automation

```text
Jira Requirement
       ↓
Rovo MCP
       ↓
GitHub Copilot Cloud Agent
       ↓
Requirement Analysis
       ↓
Code Implementation
       ↓
Automated Tests
       ↓
Feature Branch
       ↓
Commit + Push
       ↓
Pull Request
       ↓
Jira In Review
       ↓
════════════════════
    HUMAN CONTROL
════════════════════
       ↓
Code Review
       ↓
Independent Test
       ↓
Merge
       ↓
Jira Done
```

## Continuous Integration

```text
Repository Change
       ↓
GitHub Push / PR
       ↓
GitHub Actions
       ↓
Ubuntu Runner
       ↓
Java 21
       ↓
Compile
       ↓
Automated Tests
       ↓
Package
       ↓
CI Result
```

Together:

```text
Requirement
    ↓
AI-Assisted Development
    ↓
Automated Tests
    ↓
Human Review
    ↓
Merge
    ↓
CI Verification
    ↓
Build Success
```

---

# 34. Safety and Governance Rules

The AI may:

```text
✓ Read Jira
✓ Analyse repository
✓ Modify code
✓ Add/update tests
✓ Run tests
✓ Create feature branch
✓ Commit
✓ Push
✓ Create Pull Request
✓ Move To Do → In Progress
✓ Move In Progress → In Review
```

The AI should NOT:

```text
✗ Commit directly to main
✗ Merge its own Pull Request
✗ Move Jira to Done
✗ Expose credentials
✗ Store tokens in Git
✗ Duplicate existing branches or PRs
```

Human responsibility:

```text
Code Review
Test Verification
PR Approval
Merge
Jira Done
```

---

# 35. Troubleshooting

## Rovo MCP Cannot Read Jira

Check:

```text
API token authentication
Token scopes
Agent Secret
MCP configuration
Jira permissions
```

Run the read-only diagnostic again before continuing.

---

## Cannot Move Jira to In Review

Check whether the Jira workflow contains:

```text
In Progress → In Review
```

The agent cannot perform a transition that does not exist.

---

## Maven Java Version Error

Check:

```powershell
java -version
.\mvnw.cmd -version
$env:JAVA_HOME
```

The project requires Java 21.

---

## GitHub Actions Maven Wrapper Permission Denied

Error:

```text
./mvnw: Permission denied
```

Fix:

```powershell
git update-index --chmod=+x mvnw
```

Commit and push the permission change.

---

# 36. What We Learned

This project demonstrates more than AI code generation.

It combines:

```text
Requirements Management
        +
AI Agent
        +
External System Integration
        +
Software Development
        +
Automated Testing
        +
Git Workflow
        +
Pull Requests
        +
Human Governance
        +
Continuous Integration
        +
CI Troubleshooting
```

Important lessons include:

1. Jira can act as the source of requirements for an AI coding workflow.
2. MCP can connect an AI agent with external systems such as Jira.
3. AI can implement requirements while humans retain approval control.
4. Automated tests should independently verify AI-generated changes.
5. GitHub Actions can automatically validate repository changes.
6. CI runners may behave differently from local development environments.
7. A successful local build does not guarantee a successful Linux CI build.
8. CI failures should be diagnosed from logs rather than guessed.
9. Secrets must remain outside source control.
10. Human review remains an important part of AI-assisted software development.

The key principle is:

> Automate development and verification where appropriate while retaining human control over review, approval, and completion.

---

# 37. Project Status

```text
PART 1 — COPILOT + JIRA + ROVO MCP

GitHub Repository              ✅
Jira Integration               ✅
Rovo MCP                       ✅
Copilot Cloud Agent            ✅
MCP Read                       ✅
MCP Write                      ✅
CAD-2 Implementation           ✅
Automated Tests                ✅
Feature Branch                 ✅
Pull Request                   ✅
Human Review                   ✅
Human Merge                    ✅
CAD-2 Done                     ✅


PART 2 — GITHUB ACTIONS CI/CD

GitHub Actions Workflow        ✅
Push Trigger                   ✅
Pull Request Trigger Config    ✅
Manual Trigger Config          ✅
Ubuntu Runner                  ✅
Java 21 Setup                  ✅
Maven Cache                    ✅
Compile                        ✅
Automated Tests                ✅
3 Tests Passing                ✅
Package                        ✅
Linux Permission Fix           ✅
Action Versions Updated        ✅
Clean Successful Pipeline      ✅
```

---

# 38. Next Phase — Docker

The next learning phase is Docker.

The goal is to create a stable practice application/environment that can be used for automation testing without depending on public testing websites whose UI or DOM may change.

Conceptually:

```text
Practice Web Application
        ↓
Dockerfile
        ↓
Docker Image
        ↓
Docker Container
        ↓
localhost
        ↓
Stable Test Environment
        ↓
Automation Tests
```

The practice application can contain common UI components such as:

```text
Text Box
Button
Link
Dropdown
Date Picker
Other Test Elements
```

This will provide a controlled environment for future Selenium and automation-testing exercises.

---

# 39. Separate Advanced SDET Project

Advanced SDET CI/CD automation will NOT be added directly to this repository.

It will be developed as a separate project.

The planned architecture is:

```text
Scheduled / Nightly Regression
          ↓
Run Complete Test Suite
          ↓
Detect Failed Tests
          ↓
Rerun Failed Tests
          ↓
Rerun Again if Required
          ↓
Identify Persistent Failures
          ↓
Generate Final Report
          ↓
Store / Publish Report
          ↓
Optional Jira Integration
          ↓
Human Review
```

Potential future integration:

```text
GitHub Actions
      +
Regression Automation
      +
Failure Rerun
      +
Reporting
      +
Atlassian Rovo MCP
      +
Jira Defect Management
```

This advanced SDET workflow will remain separate so that this repository stays focused on:

```text
AI-Assisted Jira Development
            +
GitHub Copilot
            +
Rovo MCP
            +
Human Governance
            +
Basic CI/CD
            +
Docker Practice Environment
```

---

# Final Project Summary

```text
JIRA REQUIREMENT
      ↓
ROVO MCP
      ↓
GITHUB COPILOT
      ↓
CODE + TESTS
      ↓
FEATURE BRANCH
      ↓
PULL REQUEST
      ↓
HUMAN REVIEW
      ↓
MERGE
      ↓
GITHUB ACTIONS
      ↓
COMPILE
      ↓
AUTOMATED TESTS
      ↓
PACKAGE
      ↓
BUILD SUCCESS
```

This project demonstrates how AI-assisted software development, requirements management, automated testing, human governance, Git workflows, and Continuous Integration can work together in a practical development lifecycle.