.PHONY: \
    all \
	apply \
	init \
	clean \
	fmt \
	plan \

ifdef targets
options := $(foreach target,$(targets),-target $(target))
endif

init:
	terraform init

apply:
	terraform apply plan.out

fmt:
	terraform --version
	terraform fmt -diff -recursive

plan: fmt
	terraform plan --out=plan.out -no-color $(options) | tee plan.log

plan-destroy:
	terraform plan -destroy $(options) --out=plan.out -no-color | tee plan.log

validate: fmt
	terraform validate $(defaults)

clean:
	rm -f plan.out plan.log;

all: init plan apply
	$(info "Running init plan apply")

