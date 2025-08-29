INFRA_DIR:=./infrastructure
default: infracheck

fmt:
	@echo "==> Formatting Terraform code with terraform fmt..."
	@command -v terraform >/dev/null 2>&1 || { echo >&2 "'terraform' is required but not installed. Aborting."; exit 1; }
	@terraform fmt -recursive .

fmt-check:
	@echo "==> Checking Terraform code with terraform fmt..."
	@command -v terraform >/dev/null 2>&1 || { echo >&2 "'terraform' is required but not installed. Aborting."; exit 1; }
	@terraform fmt -recursive -check .

tflint:
	@echo "==> Checking Terraform code with tflint..."
	@command -v tflint >/dev/null 2>&1 || { echo >&2 "'tflint' is required but not installed. Aborting."; exit 1; }
	@tflint --recursive

validate:
	@echo "==> Validating Terraform code with terraform validate..."
	@command -v terraform >/dev/null 2>&1 || { echo >&2 "'terraform' is required but not installed. Aborting."; exit 1; }
	@terraform -chdir=$(INFRA_DIR) validate

trivy:
	@echo "==> Checking Terraform code with trivy..."
	@command -v trivy >/dev/null 2>&1 || { echo >&2 "'trivy' is required but not installed. Aborting."; exit 1; }
	@TF_VAR_pingone_environment_name=$(shell git rev-parse --abbrev-ref HEAD) trivy config ./

infracheck: fmt-check tflint validate trivy
	@echo "==> Infrastructure validation complete"

deploy:
	@echo "==> Deploying infrastructure..."
	@./scripts/deploy-infrastructure.sh

clean:
	@echo "==> Cleaning up infrastructure..."
	@rm -rf $(INFRA_DIR)/.terraform
	@rm -f $(INFRA_DIR)/terraform.tfstate*

.PHONY: fmt fmt-check tflint validate trivy infracheck deploy clean
