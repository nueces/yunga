# Makefile
.DEFAULT_GOAL:=help

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
	terraform init


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

