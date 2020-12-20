## Introduction

The module provisions the following resources:

- Creation and configuration of VPC
- Creation and configuration of SECURITY GROUPS
- Creation and configuration of ICDR
- Creation and configuration of IGW

## main.tf

Creation of the vpc, icdr, igw and security group.


## outputs.tf

Stores the outgoing registers of the display, to be able to be used in other variables.


## variables.tf

Variables used for module deployment


## provider.tf

Connection to aws to perform the deployment, is defined in roles.
