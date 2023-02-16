# aws-infra


## Requirements

Install Terraform 

Follow this - https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli 

Install AWS CLI 

Follow this - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html 


## Development

### Configure environment variables [example_keys]

```shell
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=ap-northeast-1
```


### Cloning and Using the Repository

```shell
git clone git@github.com:anvoruganti/aws-infra.git
cd aws-infra
terraform init 
terraform plan --auto-approve
terraform apply --auto-approve
terraform destroy --auto-approve (to destroy the instances)
```
-Modify the profile variable in terraform.tfvars file to your aws cli profile name if not using default.
