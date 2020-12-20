## Introduction

The module provisions the following resources:

- Creation and configuration of public and private SUBNETS
- Creation and configuration of ROUTE TABLES
- Creation and configuration of ASSOCIATED TABLES
- Creation and configuration of NAT-GATEWAY

## main.tf

Creation of public and private subnets, routing tables, association tables, nat gateway and network acl.


## outputs.tf

Stores the outgoing registers of the display, to be able to be used in other variables.


## variables.tf

Variables used for module deployment


## provider.tf

Connection to aws to perform the deployment, is defined in roles.