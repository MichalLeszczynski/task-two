
STACKNAME=mlesz-lambda-stack-t2
BUCKETNAME=mlesz-cloudformation-templates-t2
REGION=eu-central-1
DEPLOYED_INTERNAL_STACK=mlesz-ec2-stack

validate:
	aws cloudformation validate-template --template-body file://external-stack.yaml

deploy: package
	aws cloudformation deploy --template-file ./packaged-stack.yaml --stack-name $(STACKNAME) --capabilities CAPABILITY_NAMED_IAM

package: bucket
	find . -type d -name "*function" | xargs -I % pip install --target % -r %/requirements.txt
	aws cloudformation package \
		--template ./external-stack.yaml \
		--s3-bucket $(BUCKETNAME) \
		--output-template-file packaged-stack.yaml

bucket: 
	aws s3 mb s3://$(BUCKETNAME) || true

destroy: 
	aws cloudformation delete-stack --stack-name $(STACKNAME)

cleanup: destroy
	rm -rf stack_creator_function/*/ request_handler_function/*/
	aws s3 rm s3://$(BUCKETNAME) --recursive
	aws s3 rb s3://$(BUCKETNAME)

deploy_payload: lambda_url_output
	awscurl -X POST --service lambda --region $(REGION) -H 'Content-Type: application/json' --data '$(shell cat create_payload.json | jq  -c)' $(shell cat url.txt) -v

delete_payload: lambda_url_output
	awscurl -X POST --service lambda --region $(REGION) -H 'Content-Type: application/json' --data '$(shell cat delete_payload.json | jq  -c)' $(shell cat url.txt) -v

lambda_url_output:
	aws cloudformation describe-stacks --query 'Stacks[?StackName==`$(STACKNAME)`].Outputs[0][?OutputKey==`FunctionUrl`].OutputValue' --output=text > url.txt # hackish output indexing

payload_key_id_output:
	aws cloudformation describe-stacks --query 'Stacks[?StackName==`$(DEPLOYED_INTERNAL_STACK)`].Outputs[0][?OutputKey==`KeyPairId`].OutputValue' --output text > key_pair_id.txt # hackish output indexing

get-keys: payload_key_id_output
	echo "`aws ssm get-parameter --name /ec2/keypair/$(shell cat key_pair_id.txt) --region eu-central-1 --with-decryption | jq .Parameter.Value | cut -d '\"' -f 2`" > key.pem
	chmod 600 key.pem

payload_public_dns_output:
	aws cloudformation describe-stacks --query 'Stacks[?StackName==`$(DEPLOYED_INTERNAL_STACK)`].Outputs[1][?OutputKey==`InstanceDnsName`].OutputValue' --output text > public_dns.txt

login: get-keys payload_public_dns_output
	ssh -i ./key.pem ec2-user@$(shell cat public_dns.txt)