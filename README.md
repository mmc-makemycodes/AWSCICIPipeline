# AWSCICIPipeline

A static single-page app hosted on **AWS S3 + CloudFront** (ap-south-1), with infrastructure in **Terraform** and deploys run by **GitHub Actions** on every push to `main`.

```
site/                      SPA (HTML/CSS/JS, hash routing)
infra/                     Terraform: private S3 bucket, CloudFront (OAC), deploy IAM user
.github/workflows/         CI/CD: validate HTML -> s3 sync -> CloudFront invalidation
```

## 1. Run locally

```bash
cd site
python -m http.server 8080     # open http://localhost:8080
```

## 2. Create the infrastructure (one time)

Hosting mode is set by `enable_cloudfront` in `infra/variables.tf`:

- `false` (default): public S3 static website, HTTP only. Works on any account.
- `true`: private bucket behind CloudFront, HTTPS. New AWS accounts must first be verified
  by AWS Support (open a free "Account and billing" case quoting the CloudFront AccessDenied error).

```bash
cd infra
terraform init
terraform apply
terraform output
```

## 3. Create an access key for the deploy user

```bash
aws iam create-access-key --user-name aws-devops-poc-github-deployer
```

## 4. Add GitHub repository secrets

Repo -> Settings -> Secrets and variables -> Actions -> New repository secret

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | from step 3 |
| `AWS_SECRET_ACCESS_KEY` | from step 3 |
| `S3_BUCKET` | `terraform output -raw bucket_name` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `terraform output -raw cloudfront_distribution_id` (only when CloudFront is enabled) |

## 5. Deploy

Push a change under `site/` to `main`, or run the workflow manually from the Actions tab.
The site is served at `terraform output -raw website_url`.

## Tear down

```bash
cd infra && terraform destroy
```
Delete the deploy user's access key first if Terraform reports a conflict on the IAM user:
`aws iam list-access-keys --user-name aws-devops-poc-github-deployer`, then `aws iam delete-access-key`.
