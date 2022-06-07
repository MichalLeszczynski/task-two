# Task-one

This repo contains AWS Cloudformation stack deploying lambda function with necessary roles, that is capable of deploying CloudFormation stacks templated with Jinja2.

## Prerequisites
To run the script one need to have:
 - AWS CLI tool with permissions needed to deploy cloudformation stack
 - pip tool in order to install packages required for python

## How to deploy?
In order to deploy the stack, one needs to run command:
```
make deploy
```

## How to do the cleanup?
Run:
```
make cleanup
```
That will delete created s3 bucket and delete downloaded locally python pip packages. NOTE: this destroys only the stack containing lambda function - to destroy stack created by it you need to run API calls to the lambda function

## Invoking deployed function

Function endpoint is secured with API_IAM auth, so In order to send requests to deployed function, one need to have proper IAM permissions for that, and use proper tool as awscurl ([Invoking lambdas](https://docs.aws.amazon.com/lambda/latest/dg/urls-invocation.html))

After acquiring awscurl, you can simply run this command (NOTE! It will use params specified in create_payload.json file):
```
make deploy_payload
```


```
awscurl -X POST --region eu-central-1 --service lambda <labda url> 
```
or after specifying right data in delete_payload.json file:
```
make delete_payload
```