## Install Terraform

```
sudo dnf install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform
```
* Create new folder
```
mkdir my_app && cd $_
```

## Connect github actions with AWS

### Step 1: Create an OIDC Identity Provider in AWS

First, you must configure your AWS account to trust GitHub's authentication server.
1. Open the AWS IAM Console.
2. In the left navigation menu, click Identity providers, then click Add provider.
3. For Provider type, select OpenID Connect.
4. For Provider URL, enter exactly: https://token.actions.githubusercontent.com
5. For Audience, enter: sts.amazonaws.com
6. Click Add provider.

### Step 2: Create an IAM Role for GitHub Actions

Next, create the role that the GitHub Actions runner will assume.
1. In the IAM Console, navigate to Roles and click Create role.
2. For Trusted entity type, select Web identity.
3. Under Identity provider, select the token.actions.githubusercontent.com provider you just created.
4. For Audience, select sts.amazonaws.com.
5. Fill out your specific GitHub context to constrain access securely:
    * Organization: Your GitHub username or organization name.
    * Repository: Your specific repository name.
    * Branch (Optional): Define a branch (e.g., main) to limit deployment capabilities.
6. Click Next to attach permissions. Attach only the specific policies your workflow needs (e.g., S3 access, ECR access, or AdministratorAccess for infrastructure management).
7. Name the role (e.g., GitHubActionsWorkflowRole) and click Create role.
8. Open your newly created role and copy the Role ARN (it looks like arn:aws:iam::123456789012:role/GitHubActionsWorkflowRole).

### Step 3: Configure Your GitHub Actions Workflow

Add the AWS authentication step into your GitHub repository's workflow file (e.g., `.github/workflows/deploy.yml`). You must explicitly request id-token: write permissions so that GitHub can provide a secure token to AWS.

```yaml
name: Connect to AWS

on:
  push:
    branches: [ main ]

# Required to request the OIDC JWT token from GitHub
permissions:
  id-token: write
  contents: read

jobs:
  aws-connect:
    runs-on: ubuntu-latest
    steps:
      - name: Git clone the repository
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsWorkflowRole # Replace with your copied Role ARN
          aws-region: us-east-1 # Replace with your target AWS region
          role-session-name: GitHubActionsAutomation

      - name: Verify AWS Connection
        run: |
          aws sts get-caller-identity

```

### Set GIT credentials
```
git config --global user.email "johnandmachinelearning@github.com"
git config --global user.name "johnandmachinelearning"
```
