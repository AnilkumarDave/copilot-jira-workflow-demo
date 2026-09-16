# GitHub Copilot + Jira + Atlassian Rovo MCP Workflow Demo

## Overview

This project demonstrates how **GitHub Copilot Cloud Agent** can work with **Jira Cloud through Atlassian Rovo MCP** to implement a Jira User Story automatically while keeping important decisions under human control.

The main goal is to understand this workflow:

```text
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
Human Review
      ↓
Human Merge
      ↓
Jira → Done
```

The Spring Boot application in this repository is only a sample application used to demonstrate the workflow.

---

## Technologies

- GitHub
- GitHub Copilot Cloud Agent
- Jira Cloud
- Atlassian Rovo MCP V2
- Git
- Java 21
- Spring Boot
- Maven
- JUnit / MockMvc

---

# 1. Main Architecture

```text
┌─────────────────────┐
│      Jira Cloud     │
│   User Story CAD-2  │
└──────────┬──────────┘
           │
           │ Read / Write
           ▼
┌─────────────────────┐
│ Atlassian Rovo MCP  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ GitHub Copilot      │
│ Cloud Agent         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ GitHub Repository   │
│ Code + Tests        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Feature Branch + PR │
└──────────┬──────────┘
           │
           ▼
════════ HUMAN REVIEW ════════
           │
           ▼
      Merge + Done
```

---

# 2. Important Concepts

## GitHub Copilot Agent

The Copilot Agent is the AI worker.

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

MCP acts as a bridge between the AI agent and external systems.

In this project:

```text
GitHub Copilot
      ↓
Atlassian Rovo MCP
      ↓
Jira Cloud
```

This allows Copilot to interact with Jira instead of requiring the Jira requirement to be copied manually into the prompt.

---

## Human-in-the-Loop

The AI performs development work, but important approval actions remain with a human.

```text
AI:
Requirement → Code → Tests → Branch → PR → In Review

Human:
Review → Verify → Merge → Done
```

The agent must NOT automatically merge its own Pull Request or move the Jira story to Done.

---

# 3. Prerequisites

Before building this workflow, prepare:

### GitHub

- GitHub repository
- GitHub Copilot with Cloud Agent capability
- Copilot Agent enabled
- Repository access
- Agent Secrets access
- MCP server configuration access

### Atlassian

- Jira Cloud site
- Jira project
- Atlassian Rovo MCP enabled
- API-token authentication enabled
- Jira read/search/write permissions

### Local Development

- Git
- Java 21
- Maven / Maven Wrapper
- IntelliJ IDEA or another IDE

---

# 4. Jira Setup

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

# 5. Jira Workflow

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

The intended responsibility is:

```text
Copilot:
To Do → In Progress → In Review

Human:
In Review → Done
```

This is an important safeguard.

---

# 6. Configure Atlassian Rovo MCP

In Atlassian Administration, open the Rovo MCP server configuration.

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

# 7. Create Scoped Atlassian API Token

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

Do not put the API token into source code or commit it to Git.

---

# 8. Prepare Authentication

For API-token authentication, create:

```text
ATLASSIAN_EMAIL:ATLASSIAN_API_TOKEN
```

and Base64 encode it.

PowerShell example:

```powershell
$pair = "YOUR_ATLASSIAN_EMAIL:YOUR_API_TOKEN"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
[Convert]::ToBase64String($bytes)
```

Important:

> Base64 is encoding, not encryption.

The Base64 result must therefore also be treated as a secret.

---

# 9. GitHub Agent Secret

Store the Base64 authentication value as a GitHub **Agent Secret**.

Secret used in this project:

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

Never store the actual secret value in this README.

---

# 10. Configure Rovo MCP in GitHub

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
```

The GitHub Cloud Agent MCP configuration is separate from IntelliJ/IDE MCP configuration.

Therefore, configuring MCP in GitHub does not automatically configure the same MCP server inside IntelliJ.

---

# 11. Test MCP Before Automation

Before allowing the AI to modify anything, perform a read-only diagnostic.

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

Always verify MCP connectivity before building a larger automation.

---

# 12. Baseline Application

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

# 13. Copilot Agent Instructions

The agent was given rules similar to:

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

These rules are important because they prevent the AI from completing the entire lifecycle without human approval.

---

# 14. What Copilot Did

For CAD-2, Copilot:

```text
Read CAD-2
     ↓
Moved CAD-2 → In Progress
     ↓
Inspected repository
     ↓
Implemented password validation
     ↓
Updated automated tests
     ↓
Ran tests
     ↓
Created feature branch
     ↓
Committed changes
     ↓
Pushed branch
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

# 15. Implementation Result

Copilot added validation so an empty password is rejected.

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

Copilot also added/updated automated tests for:

```text
Empty password → 400 Bad Request

Valid password → 201 Created
```

---

# 16. Verify the AI's Work

Do not trust an AI-generated Pull Request without verification.

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

# 17. Human Review and Merge

After verification:

```text
Copilot PR
    ↓
Human reviews code
    ↓
Human verifies acceptance criteria
    ↓
Human runs tests
    ↓
Human marks PR ready
    ↓
Human merges PR
```

Copilot was NOT allowed to merge the PR.

After the successful human merge:

```text
CAD-2

In Review
    ↓
Done
```

was performed manually.

---

# 18. Complete End-to-End Result

The completed demo proves:

```text
Jira CAD-2
    ↓
Rovo MCP
    ↓
GitHub Copilot Agent
    ↓
Requirement Analysis
    ↓
Code Implementation
    ↓
Automated Testing
    ↓
Feature Branch
    ↓
Commit + Push
    ↓
Pull Request
    ↓
Jira In Review
    ↓
══════════════════
   HUMAN CONTROL
══════════════════
    ↓
Code Review
    ↓
Independent Test
    ↓
Merge
    ↓
Jira Done
```

---

# 19. Safety Rules

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

# 20. Troubleshooting

### Rovo MCP cannot read Jira

Check:

```text
API token authentication
Token scopes
Agent Secret
MCP configuration
Jira permissions
```

Run the read-only diagnostic again before continuing.

### Cannot move Jira to In Review

Check whether the Jira workflow contains:

```text
In Progress → In Review
```

The agent cannot perform a transition that does not exist.

### Maven Java Version Error

Check:

```powershell
java -version
.\mvnw.cmd -version
$env:JAVA_HOME
```

The project requires Java 21.

---

# 21. What We Learned

This project demonstrates more than AI code generation.

It demonstrates:

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
Pull Request
        +
Human Governance
```

The key principle is:

> Let AI automate development work, while humans retain control over review, approval and completion.

---

# 22. Next Phase

The manual end-to-end workflow is complete.

The next phase is:

```text
Reusable Jira Developer Agent
            ↓
Reusable Instructions / Skills
            ↓
GitHub Automation
            ↓
Automatic Trigger
            ↓
Jira → Code → Tests → PR
            ↓
Human Review
```

Later, the same architecture can be extended for SDET workflows such as:

```text
Scheduled Regression Tests
          ↓
Detect Failure
          ↓
Rerun Failure
          ↓
Analyse Failure
          ↓
Create Jira Bug
          ↓
Generate Report
          ↓
Human Review
```

---

## Project Status

```text
GitHub Repository       ✅
Jira Integration        ✅
Rovo MCP                ✅
Copilot Cloud Agent     ✅
MCP Read                ✅
MCP Write               ✅
CAD-2 Implementation    ✅
Automated Tests         ✅
Feature Branch          ✅
Pull Request            ✅
Human Review            ✅
Human Merge             ✅
CAD-2 Done              ✅

Next:
Reusable Agent + Automation
```