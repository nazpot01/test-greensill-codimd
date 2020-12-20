# Introduction

This project allows an automated deployment of terraform from modules, ECR, EKS, KMS, SUBNET, VPC, among others. The project must be executed from a machine that is within the same network that will apply the changes, otherwise it may be necessary to modify the **provider.tf** file of each module and the main module, since file **provider.tf** is configured for a role with permissions to the modules to be created.

### Prerequisites 📋

_ What things do you need? _

1. Have Docker 12.03.8 or higher installed

2. Have **terraform v0.12.28** installed to execute the commands on the machine that you are going to perform the deployment.

3. Have **kubectl** installed and configured to run kubernetes commands.

4. Have an **AWS** role (this must be called "terraform") with permissions to the services to be executed (ECR, EKS, etc).

5. Have a locally configured profile with connection credentials to **AWS** (Secret key and access key)



## Starting 🔧


### Deployment of infrastructure

_What you should do .._

1. Make a copy of the repository **(https://github.com/nazpot01/test-greensill-codimd.git)** in your local repository

2. Execute command **"terraform init"** in the folder where the downloaded repository is located, in order to initialize terraform.

3. Make the modification of the variables you consider in the file **variablesqa.tfvars**. This file contains the transversal variables for the display of all the modules. (There are already some example values)

4. In the file **variablesqa.tfvars**, in the following variables, make the modification for your aws account number:

		aws_account_id_project = "indicate_the_number_of_aws_account"
		aws_account_id_glyc = "indicate_the_number_of_aws_account"

5. Perform the deployment from the machine that is on the network with the following command: **terraform plan -var-file = variablesqa.tfvars -out = newscore.plan** and **terraform apply "newscore.plan"**

6. Once the infrastructure is implemented, modify the **pipelines-node.yml** file with the information that requires parameterization, it is important that you verify the template well since the mapping to the **ECR** image is performed here . To initialize the Kubernetes Ingress controller you must run the following command:

		kubectl apply -f pipelines-node.yml

##### NOTE

Only if the role was created with another name make this change. In the **provider.tf** files of each module and the main one, the role must be added in the variable:

	role_arn = arn:aws:iam::%s:role/role_name


### Image preparation

1. Make a copy of the repository **(https://github.com/hackmdio/codimd.git)** in your local repository

2. Go to the folder **deployments** and locate the file **dockerfile**, move it to the root of the project

3. Go to the root of the project and execute the following commands:

docker build -t "codimd".

4. Create a project tag:

docker tag codimd: latest

5. Check connection with **AWS** locally for image upload to ECR.

6. Upload the image to the ECR repository replacing the account details:

docker push aws_account_id.dkr.ecr.region.amazonaws.com/codimd:latest


## Contributing 🖇️

Holman Hernandez