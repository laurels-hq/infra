# Laurels Infra

> :lock: This is a redacted copy of our Terraform config that lives in the main app repo. Feel free to check it out and let us know if you can help!

## VPCs

Laurels is setup with a dedicated VPC per environment. Subnetting has been setup to provide reasonable IP spaces for expected growth over the next 3 years.

## State

State is persisted in S3 and configured in the `terraform.tf` file. There are special AWS credentials in that file which only allow access to the state S3 bucket and a DynamoDB table to handle deployment locks.

## Environments

In order to control for environments, Terraform workspaces are utilized, one per environment. If you want to initialize a new environment, you will need to create a new workspace and update the `variables.tf` file with the approriate attributes.

You can locally select your environment by using `terraform workspace select dev` (where "dev" is the env you want to control).

## Deployment

All changes are deployed using GitHub actions, and will be deployed upon merging into the `prod` or `dev` branches, respectively.

After a build artifact is created by the CI, an SSM parameter for that environment is updated. Terraform will read the value of this parameter each time it is run, and if the currently deployed image differs from what is expected, it will update the deployment and roll out the new image.

All code is run on AWS Elastic Compute Service under Fargate. When new code is deployed, the new image is spun up, and one a health check passes (HTTP 200 on `/`) it will drain & terminate the old image.

If there is an issue with the new image, the old image will not terminate. AWS will continue to try to launch the new image, so it is recommended to fix the deployment quickly to avoid spending money on resources which will not start.
