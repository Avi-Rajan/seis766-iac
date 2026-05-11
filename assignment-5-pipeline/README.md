# Assignment — Software Delivery Pipeline (CloudFormation)

Builds an automated delivery pipeline on AWS using GitHub, CodeBuild, and CodePipeline. Everything is provisioned through a single CloudFormation template.

## Architecture

```
GitHub repo (Java source)
        │
        ▼
CodePipeline ── Source stage (GitHub webhook/poll)
        │
        ▼
       Build stage ──▶ CodeBuild (mvn package) ──▶ S3 artifact bucket
```

The pipeline has two stages:
- **Source** — pulls the Java project from a GitHub repo
- **Build** — runs CodeBuild against the source, producing a `.jar` artifact stored in S3

## Files

| File | Purpose |
|---|---|
| `pipeline.json` | CloudFormation template (artifact bucket + IAM roles + CodeBuild project + CodePipeline pipeline) |
| `buildspec.yml` | Build instructions for CodeBuild. Lives in the Java project repo. |

## Java source

Source code for the Java app is provided by the assignment at:
`https://seis665-public.s3.amazonaws.com/java-project.zip`

Unzip it into its own GitHub repo, drop `buildspec.yml` at the repo root, then point this pipeline at that repo via the stack parameters.

## Deploy

1. Create a GitHub personal access token with `repo` and `admin:repo_hook` scopes.
2. Deploy the stack:

```bash
aws cloudformation create-stack \
  --stack-name java-delivery-pipeline \
  --template-body file://pipeline.json \
  --capabilities CAPABILITY_IAM \
  --parameters \
      ParameterKey=GitHubOwner,ParameterValue=<your-github-username> \
      ParameterKey=GitHubRepo,ParameterValue=<your-java-repo-name> \
      ParameterKey=GitHubBranch,ParameterValue=main \
      ParameterKey=GitHubOAuthToken,ParameterValue=<your-token>
```

3. Trigger the pipeline manually the first time (Console → CodePipeline → *Release change*) or just push a commit to the branch.

4. Watch both stages go green. The built `.jar` lands in the artifact bucket under `<pipeline-name>/BuildOutput/`.

## Troubleshooting

Pipeline failures are almost always IAM permission issues. Check:
- CodePipeline → failed action → details → CloudWatch logs link
- CodeBuild → build history → phase that failed

## Teardown

```bash
# Empty the artifact bucket first (CloudFormation will not delete a non-empty bucket)
aws s3 rm s3://<artifact-bucket-name> --recursive

aws cloudformation delete-stack --stack-name java-delivery-pipeline
```

Then delete the GitHub personal access token.
