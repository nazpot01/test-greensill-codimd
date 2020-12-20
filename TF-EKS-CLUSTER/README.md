## Introduction

The module provisions the following resources:

- EKS cluster of master nodes
- IAM Role to allow the cluster to access other AWS services
- Security Group which is used by EKS workers to connect to the cluster and kubelets and pods to receive communication from the cluster control plane
- The module creates and automatically applies an authentication ConfigMap to allow the wrokers nodes to join the cluster and to add additional users/roles/accounts

## main.tf

It contains the creation of the cluster, role and policy.


## auth.tf



## outputs.tf

Stores the outgoing registers of the display, to be able to be used in other variables.


## variables.tf

Variables used for module deployment


## provider.tf

Connection to aws to perform the deployment, is defined in roles.
