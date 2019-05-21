all: cpu gpu

cpu:
	cd cpu-images && \
	terraform init && \
	terraform apply -auto-approve -var-file ../build-env.tfvars && \
	terraform destroy -auto-approve -var-file ../build-env.tfvars

gpu:
	echo "Not implemented yet"

clean:
	cd cpu-images && \
        terraform destroy -auto-approve -var-file ../build-env.tfvars
