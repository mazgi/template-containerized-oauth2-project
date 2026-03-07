# OIDC Setup

One-time setup per cloud provider. These create trust relationships between GitHub's OIDC token issuer and your cloud accounts.

## AWS: IAM OIDC Provider + IAM Role

1. **Create the OIDC identity provider:**

   ```sh
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
   ```

   > **Note:** Since July 2023, AWS has added GitHub to its trusted root CAs, so the thumbprint value is no longer validated ([announcement](https://github.blog/changelog/2023-07-13-github-actions-oidc-integration-with-aws-no-longer-requires-pinning-of-intermediate-tls-certificates/)). The `--thumbprint-list` parameter is still required by the CLI, but the value is effectively ignored.

2. **Create an IAM role with a trust policy:**

   Create `trust-policy.json` (replace `ACCOUNT_ID` and `OWNER/REPO`):

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
           },
           "StringLike": {
             "token.actions.githubusercontent.com:sub": "repo:OWNER/REPO:*"
           }
         }
       }
     ]
   }
   ```

   ```sh
   aws iam create-role \
     --role-name github-actions-iac \
     --assume-role-policy-document file://trust-policy.json
   ```

3. **Attach permissions.** The role needs access to: S3 (state backend), ECR, ECS, VPC, RDS, IAM (for ECS execution roles).

4. **Set the variable:** Add `AWS_IAM_ROLE_ARN` to GitHub Actions variables.

**Tip:** For tighter control, restrict the `sub` condition to specific branches or environments, e.g. `repo:OWNER/REPO:ref:refs/heads/main` or `repo:OWNER/REPO:environment:persistent`.

## Azure: Federated Identity Credentials

1. **Create an Azure AD app registration** (if not already done):

   ```sh
   az ad app create --display-name "github-actions-iac"
   ```

   Note the `appId` — this becomes `ARM_CLIENT_ID`.

2. **Create a service principal:**

   ```sh
   az ad sp create --id <APP_ID>
   ```

3. **Add federated identity credentials** for each subject the workflows use (replace `OWNER/REPO`):

   ```sh
   # For the main branch (plan/apply on push)
   az ad app federated-credential create --id <APP_ID> --parameters '{
     "name": "github-main",
     "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:OWNER/REPO:ref:refs/heads/main",
     "audiences": ["api://AzureADTokenExchange"]
   }'

   # For pull requests (plan on PR)
   az ad app federated-credential create --id <APP_ID> --parameters '{
     "name": "github-pr",
     "issuer": "https://token.actions.githubusercontent.com",
     "subject": "repo:OWNER/REPO:pull_request",
     "audiences": ["api://AzureADTokenExchange"]
   }'
   ```

4. **Assign RBAC roles** to the service principal:

   ```sh
   az role assignment create \
     --assignee <APP_ID> \
     --role Contributor \
     --scope /subscriptions/<SUBSCRIPTION_ID>
   ```

   Also grant `Storage Blob Data Contributor` on the Terraform state storage account for backend access.

5. **Set the variables:** Add `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` to GitHub Actions variables.

**Important:** Azure AD federated credentials are scoped per `subject` claim. The OIDC token subject varies by context: `repo:OWNER/REPO:ref:refs/heads/main` on push, `repo:OWNER/REPO:pull_request` on PR, `repo:OWNER/REPO:environment:persistent` or `environment:ephemeral` when using GitHub Environments.

## Google Cloud: Workload Identity Federation

1. **Create a Workload Identity Pool:**

   ```sh
   gcloud iam workload-identity-pools create github \
     --project=PROJECT_ID \
     --location=global \
     --display-name="GitHub Actions"
   ```

2. **Create a Workload Identity Provider:**

   ```sh
   gcloud iam workload-identity-pools providers create-oidc github \
     --project=PROJECT_ID \
     --location=global \
     --workload-identity-pool=github \
     --display-name="GitHub" \
     --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
     --attribute-condition="assertion.repository == 'YOUR_GITHUB_USER/YOUR_REPO_NAME'" \
     --issuer-uri="https://token.actions.githubusercontent.com"
   ```

3. **Create a service account** (if not already done):

   ```sh
   gcloud iam service-accounts create github-actions-iac \
     --project=PROJECT_ID \
     --display-name="GitHub Actions IaC"
   ```

4. **Grant the service account necessary roles:**

   ```sh
   # Adjust roles based on your needs
   for role in roles/owner roles/storage.admin; do
     gcloud projects add-iam-policy-binding PROJECT_ID \
       --member="serviceAccount:github-actions-iac@PROJECT_ID.iam.gserviceaccount.com" \
       --role="$role"
   done
   ```

5. **Allow the GitHub identity to impersonate the service account** (replace `OWNER/REPO`):

   ```sh
   gcloud iam service-accounts add-iam-policy-binding \
     github-actions-iac@PROJECT_ID.iam.gserviceaccount.com \
     --project=PROJECT_ID \
     --role="roles/iam.workloadIdentityUser" \
     --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github/attribute.repository/OWNER/REPO"
   ```

6. **Get the provider resource name:**

   ```sh
   gcloud iam workload-identity-pools providers describe github \
     --project=PROJECT_ID \
     --location=global \
     --workload-identity-pool=github \
     --format="value(name)"
   ```

   This returns: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/github`

7. **Set the variables:** Add `GOOGLE_WORKLOAD_IDENTITY_PROVIDER`, `GOOGLE_SERVICE_ACCOUNT`, and `GOOGLE_PROJECT_ID` to GitHub Actions variables.
