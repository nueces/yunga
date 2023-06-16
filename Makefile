# Makefile
.DEFAULT_GOAL:=help

define usage
	# The sed command use the {#}\2 to avoid using two consecutive #
	@echo "\nUsage: make <target> "\
		 "[one or more targets separated by spaces and in the order that their would executed]\n\n"\
		 "The following targets are available: \n"
	@sed -e '/#\{2\}@/!d; s/\\$$//; s/:[^#\t]*/\n\t\t\t/; s/^/\t/; s/#\{2\}@ *//' $(MAKEFILE_LIST)
	@echo "\n"
endef

# Configurations
UTILS=utils
INFRASTRUCTURE=infrastructure
PLAYBOOKS=playbooks

# Packages installed in the virtualenv place their commands in the bin directory inside virtualenv path.
# So we are going to prefix all commands with virtualenv bin path.
VENV_PATH = $(or ${VIRTUAL_ENV}, "venv")

# Ansible
ANSIBLE_GALAXY   = ${VENV_PATH}/bin/ansible-galaxy
ANSIBLE_PLAYBOOK = ${VENV_PATH}/bin/ansible-playbook
ANSIBLE_PULL     = ${VENV_PATH}/bin/ansible-pull
ANSIBLE_LINT     = ${VENV_PATH}/bin/ansible-lint

# python commands
PYTHON = ${VENV_PATH}/bin/python3
PIP    = ${VENV_PATH}/bin/pip
BLACK  = ${VENV_PATH}/bin/black
ISORT  = ${VENV_PATH}/bin/isort
PYLINT = ${VENV_PATH}/bin/pylint

#############################################################################

.PHONY: help
help: ##@ Show this help.
	@$(usage)

.PHONY: bootstrap
bootstrap: ##@ Create the virtualenv to run pip-install target.
	rm -rfv ${VENV_PATH}
	python3 -m venv ${VENV_PATH}
	# Install ansible and python dependencies
	@$(MAKE) pip-install
	${PYTHON} utils/bootstrap.py


.PHONY: pip-install
pip-install: ##@ Install python dependencies using pip.
	${PIP} install --requirement requirements.txt


.PHONY: pip-upgrade
pip-upgrade: ##@ Upgrade python dependencies using pip. This ignore pinning versions in requirements.txt.
	${PIP} install --upgrade $(shell sed -e '/^[a-zA-Z0-9\._-]/!d; s/=.*$$//' requirements.txt)


.PHONY: pip-freeze
pip-freeze:##@ Like pip freeze but only for packages that are in requirements.txt.
##@		This doesn't include any package that could be present in the virtualenv
##@		as result of manual installs or resolved dependencies.
	REQ="$(shell ${PIP} freeze --quiet --requirement requirements.txt | sed '/^## The following requirements were added by pip freeze:$$/,$$ d')";\
	echo $$REQ | sed 's/ /\n/g' > requirements.txt


.PHONY: pip-uninstall
pip-uninstall: ##@ Uninstall python dependencies using pip.
	${PIP}  pip uninstall --yes --requirement requirements.txt


galaxy-install: playbooks/requirements.yml ##@ Install ansible modules using ansible-galaxy.
	${ANSIBLE_GALAXY} collection install --requirement playbooks/requirements.yml


.PHONY: deploy
deploy: ##@ Deploy infrastructure running terraform.
	$(info >>> For more specific terraform related targets. Execute `make help` in the ${INFRASTRUCTURE} directory)
	make -C ${INFRASTRUCTURE} deploy


.PHONY: destroy
destroy: ##@ Destroy infrastructure running terraform.
	$(info >>> For more specific terraform related targets. Execute `make help` in the ${INFRASTRUCTURE} directory)
	make -C ${INFRASTRUCTURE} destroy


#TODO: Set the exclude in the pyproject.toml file.
.PHONY: ansible-lint
ansible-lint: galaxy-install ##@Run linting tools for Ansible code in the ${PLAYBOOKS} directory.
	@echo Running Ansible linting tools.
	${ANSIBLE_LINT} ${PLAYBOOKS} --exclude=${PLAYBOOKS}/requirements.yml || echo "[MASK ERROR]"


.PHONY: python-lint
python-lint: ##@ Run linting tools for python code in the ${UTILS_SRC} directory.
	@echo Running Python linting tools.
	${BLACK} ${UTILS}
	${ISORT} ${UTILS}
	${PYLINT} ${UTILS}


.PHONY: terraform-lint
terraform-lint: ##@Run linting tools for terraform code in the ${INFRASTRUCTURE} directory.
	@echo Running Terraform linting tools.
	make -C ${INFRASTRUCTURE} fmt validate


.PHONY: lint
lint: ansible-lint python-lint terraform-lint ##@ Run linting tools for Ansible, Python and Terraform code.
	@echo Lint done!


##@
##@ The following targets are not availables, and needs to be re implemented.
##@ =========================================================================
##@
# TODO: Simulate ansible-pull behaviour with ansible-playbook for speed up local development. Vagrant?

#.PHONY: play
#play: galaxy-up ##@ Run ansible-playbook.
#	${ANSIBLE_PLAYBOOK} playbooks/${TARGET}.yml
#
#.PHONY: debug
#debug: ##@ Run ansible-playbook, but only plays and tasks tagged with 'debug'.
#	${ANSIBLE_PLAYBOOK} playbook.yml --tags debug
#.PHONY: debug
#debug:
#

##############################################################################
## Deployment targets
## TODO: Validate TARGET and REPO_URL
##
#.PHONY: ansible-pull
#ansible-pull: ##@ Run ansible-pull. Note that this command make a new checkout in the path: ${HOME}/ansible-pull
#	@echo ${ANSIBLE_PULL} --accept-host-key --url=${REPO_URL} --directory ${HOME}/ansible-pull --extra-vars \"venv_path=${VENV_PATH}\" playbooks/${TARGET}.yml
#

