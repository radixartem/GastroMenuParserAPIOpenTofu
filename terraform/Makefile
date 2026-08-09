ENV ?= production
TF_DIR := live/$(ENV)

.PHONY: init fmt validate plan apply

init:
	cd $(TF_DIR) && terraform init -backend-config=backend.hcl

fmt:
	terraform fmt -recursive

validate:
	cd $(TF_DIR) && terraform validate

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply
