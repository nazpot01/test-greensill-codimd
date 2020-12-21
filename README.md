# Introduction

This project performs an automated deployment of terraform from modules, ECR, EKS, KMS, SUBNET, VPC, among others. The project must be executed from a machine that is within amazon to be able to assume roles, otherwise it may be necessary to modify the **provider.tf** file of each module and the project module, since it is configured to assume a role and you must map the **secret key and access key** credentials.

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

		1. aws_account_id_project = "indicate_the_number_of_aws_account"

		2. aws_account_id_glyc = "indicate_the_number_of_aws_account"

5. Perform the deployment from the machine that is on the network with the following command: 

        1. terraform plan -var-file = variablesqa.tfvars -out = newscore.plan 
        
        2. terraform apply "newscore.plan"

##### NOTE

Only if the role was created with another name make this change. In the **provider.tf** files of each module and the main one, the role must be added in the variable:

        role_arn = arn:aws:iam::%s:role/role_name


### Image preparation

1. Make a copy of the repository **(https://github.com/hackmdio/codimd.git)** in your local repository

2. Go to the folder **deployments** and locate the file **dockerfile**, move it to the root of the project

3. Go to the root of the project and execute the following commands:

        docker build -t "codimd" .

4. Create a project tag:

        docker tag codimd:latest

5. Check connection with **AWS** locally for image upload to ECR.

6. Upload the image to the ECR repository replacing the account details:

        docker push aws_account_id.dkr.ecr.region.amazonaws.com/codimd:latest

### Kubernets configuration

1. Run the Ingress file **deploy.yaml** with the following command:

        kubectl apply -f deploy.yaml

2. Configure in the file **app-coimd.yaml** Ingress, service, and deployment of the codimd application, change the following variables:

     #Ingress type configuration

         Host: place_app_domain
    
     #Configuration type Deployment
        
         image: full_url_of_the_image

3. Cuando las imagenes son actualizadas en ECR, ejecutar el siguiente comando:

        kubectl set image deployment/codimd codimd=URL_img:1.9.1"

