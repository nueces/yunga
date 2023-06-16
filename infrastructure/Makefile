# Makefile
.DEFAULT_GOAL:=help

PYTHON=../venv/bin/python
YAMLCONFIG=${PYTHON} ../utils/yamlconfig.py ../configuration.yml

PROJECT_NAME:=$(shell ${YAMLCONFIG} project_name | tr '[:upper:]' '[:lower:]')
TF_STATE_NAME=$(shell ${YAMLCONFIG} terraform.state_name)
PROJECT_ID:=$(shell ${YAMLCONFIG} git.project_id)
TF_USERNAME:=$(shell ${YAMLCONFIG} git.username)
TF_PASSWORD:=$(shell cat "../$(shell ${YAMLCONFIG} vault_path)/$(shell ${YAMLCONFIG} git.token_filename)")
TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/${TF_STATE_NAME}"

ifdef targets
options := $(foreach target,$(targets),-target $(target))
endif

define usage
	# The sed command use the {#}\2 to avoid using two consecutive #
	@echo "\nUsage: make <target> "\
		 "[one or more targets separated by spaces and in the order that their would executed]\n\n"\
		 "The following targets are available: \n"
	@sed -e '/#\{2\}@/!d; s/\\$$//; s/:[^#\t]*/\n\t\t\t/; s/^/\t/; s/#\{2\}@ *//' $(MAKEFILE_LIST)
	@echo "\n"
endef

.PHONY: help
help: ##@ Show this help.
	@$(usage)


.PHONY: init
init: ##@ Run terraform init.
	terraform --version
	terraform init \
	  -backend-config=address=${TF_ADDRESS} \
	  -backend-config=lock_address=${TF_ADDRESS}/lock \
	  -backend-config=unlock_address=${TF_ADDRESS}/lock \
	  -backend-config=username=${TF_USERNAME} \
	  -backend-config=password=${TF_PASSWORD} \
	  -backend-config=lock_method=POST \
	  -backend-config=unlock_method=DELETE \
	  -backend-config=retry_wait_min=5

.PHONY: migrate-state
migrate-state: ##@ Run terraform init -migrate-state.
	terraform --version
	terraform init -migrate-state \
	  -backend-config=address=${TF_ADDRESS} \
	  -backend-config=lock_address=${TF_ADDRESS}/lock \
	  -backend-config=unlock_address=${TF_ADDRESS}/lock \
	  -backend-config=username=${TF_USERNAME} \
	  -backend-config=password=${TF_PASSWORD} \
	  -backend-config=lock_method=POST \
	  -backend-config=unlock_method=DELETE \
	  -backend-config=retry_wait_min=5


.PHONY: plan
plan: fmt ##@ Run terraform format, and terraform plan storing the plan for the apply phase.
	terraform plan --out=plan.out -no-color $(options) | tee plan.log


.PHONY: plan-destroy
plan-destroy: ##@ Run terraform plan -destroy storing the plan for the apply phase.
##@		A TARGETS variable containing a space separated list of resources can by provided
##@		to processed and used as targets with -target.
	terraform plan -destroy $(options) --out=plan.out -no-color | tee plan.log


.PHONY: apply
apply: ##@ Runs terraform apply with a previous created plan.
	terraform apply plan.out


.PHONY: deploy
deploy: ##@ Runs the init, plan, and apply targets.
	$(info "Running init plan apply")
	@$(MAKE) init plan apply


.PHONY: destroy
destroy: ##@ Runs terraform destroy.
	$(info "Kaboom")
	terraform destroy


# Helpers
.PHONY: fmt
fmt: ##@ Runs terraform format updating the needed files.
	terraform fmt -diff -recursive


.PHONY: validate
validate: fmt ##@ Runs fmt target and terraform validate.
	terraform validate


.PHONY: clean
clean: ##@ Clean saved plans and logs.
	rm -f plan.out plan.log;

