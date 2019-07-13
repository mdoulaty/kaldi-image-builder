tag=latest
all: cpu gpu

cpu:
	cd cpu-images; \
	terraform init && \
	terraform apply -auto-approve -var-file ../build-env.tfvars -var "image_tag=$(tag)"; \
	terraform destroy -auto-approve -var-file ../build-env.tfvars

gpu:
	cd gpu-images; \
        terraform init && \
        terraform apply -auto-approve -var-file ../build-env.tfvars -var "image_tag=gpu-$(tag)"; \
        terraform destroy -auto-approve -var-file ../build-env.tfvars

clean:
	cd cpu-images; \
        terraform destroy -auto-approve -var-file ../build-env.tfvars; \
	cd ../gpu-images; \
	terraform destroy -auto-approve -var-file ../build-env.tfvars
