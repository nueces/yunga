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


# Packages installed in the virtualenv place their commands in the bin directory inside virtualenv path.
VENV_PATH=$(or $VIRTUAL_ENV, "venv")
# prefix all commands with virtualenv bin path
ANSIBLE_GALAXY = ${VENV_PATH}/bin/ansible-galaxy
ANSIBLE_PLAYBOOK = ${VENV_PATH}/bin/ansible-playbook
ANSIBLE_PULL = ${VENV_PATH}/bin/ansible-pull

PIP = ${VENV_PATH}/bin/pip

.PHONY: help
help: ##@ Show this help.
	@$(usage)

.PHONY: bootstrap
bootstrap: ##@ Create the virtualenv to run pip-install, and galaxy-play targets.
	rm -rfv ${VENV_PATH}
	virtualenv ${VENV_PATH}
	# Install ansible and python dependencies
	@$(MAKE) pip-install galaxy-install

.PHONY: pip-install
pip-install: ##@ Install python dependencies using pip.
	${PIP} install --requirement requirements.txt

.PHONY: pip-upgrade
pip-upgrade: ##@ Upgrade python dependencies using pip. This ignore pinning versions in requirements.txt.
	${PIP} install --upgrade $(shell sed -e '/^[a-zA-Z0-9\._-]/!d; s/=.*$$//' requirements.txt)

.PHONY: pip-freeze
pip-freeze: ##@ Like pip freeze but only for packages that are in requirements.txt. This doesn't include any package that could be present in the virtualenv as result of manual installs or resolved dependencies.
	REQ="$(shell ${PIP} freeze --quiet --requirement requirements.txt | sed '/^## The following requirements were added by pip freeze:$$/,$$ d')";\
	echo $$REQ | sed 's/ /\n/g' > requirements.txt

.PHONY: pip-uninstall
pip-uninstall: ##@ Uninstall python dependencies using pip.
	${PIP}  pip uninstall --yes --requirement requirements.txt

galaxy-install: playbooks/requirements.yml ##@ Install ansible modules using ansible-galaxy.
	${ANSIBLE_GALAXY} collection install --requirement playbooks/requirements.yml

# TODO: Simulate ansible-pull behaviour with ansible-playbook for speed up local development. Vagrant?
#.PHONY: play
#play: galaxy-up ##@ Run ansible-playbook.
#	${ANSIBLE_PLAYBOOK} playbooks/${TARGET}.yml
#
#.PHONY: debug
#debug: ##@ Run ansible-playbook, running only plays and tasks tagged with 'debug'.
#	${ANSIBLE_PLAYBOOK} playbook.yml --tags debug
#.PHONY: debug
#debug:
#

##############################################################################
## Deployment targets
## TODO: Validate TARGET and REPO_URL
##
#.PHONY: ansible-pull
#ansible-pull: ##@ Run ansible-pull. Note that this command make a new checkout in the ${HOME}/ansible-pull
#	@echo ${ANSIBLE_PULL} --accept-host-key --url=${REPO_URL} --directory ${HOME}/ansible-pull --extra-vars \"venv_path=${VENV_PATH}\" playbooks/${TARGET}.yml
#

