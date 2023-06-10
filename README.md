# Yunga


## Bootstrap
The bootstrap target creates a set following set of resources:
- An s3 bucket to be used as a backend storage for terraform state files.
- A Key pair for accessing to the EC2 instances to be deployed. This key pair are storage inside the `vault` directory.


```shell
make bootstrap
```


## Deploy infraestructura

### Prerequisites:

#### GitLab deployment token:
- A deployment token must be created and the content stored in `vault/deploy_tocken`. 
- If the token is not provided, the deployment does not fail but the instances are not provisioned. 


```shell
make deploy
```

## Development

### Ansible
At the moment the development workflow to use ansible-pull is cumbersome, as you need to commit every change in order to
test the results. I should investigate how this can be improved.

Main Makefile targets
```
Usage: make <target>  [one or more targets separated by spaces and in the order that their would executed]

 The following targets are available: 

	help
			Show this help.
	bootstrap
			Create the virtualenv to run pip-install target.
	pip-install
			Install python dependencies using pip.
	pip-upgrade
			Upgrade python dependencies using pip. This ignore pinning versions in requirements.txt.
	pip-freeze
			Like pip freeze but only for packages that are in requirements.txt.
			This doesn't include any package that could be present in the virtualenv
			as result of manual installs or resolved dependencies.
	pip-uninstall
			Uninstall python dependencies using pip.
	deploy
			Deploy infrastructure running terraform.
	destroy
			Destroy infrastructure running terraform.
	
	The following targets are not availables, and needs to be re implemented.
	=========================================================================
	
	#galaxy-install
			Install ansible modules using ansible-galaxy.
	#play
			Run ansible-playbook.
	#debug
			Run ansible-playbook, but only plays and tasks tagged with 'debug'.
	#ansible-pull
			Run ansible-pull. Note that this command make a new checkout in the path: ${HOME}/ansible-pull


```


### Terraform
Inside the `infratructure` directory there are a set of specific make targets to use during the development phase.   
```
Usage: make <target>  [one or more targets separated by spaces and in the order that their would executed]

 The following targets are available: 

	help
			Show this help.
	init
			Run terraform init.
	plan
			Run terraform format, and terraform plan storing the plan for the apply phase.
	plan-destroy
			Run terraform plan -destroy storing the plan for the apply phase.
			A TARGETS variable containing a space separated list of resources can by provided
			to processed and used as targets with -target.
	apply
			Runs terraform apply with a previous created plan.
	deploy
			Runs the init, plan, and apply targets.
	destroy
			Runs terraform destroy.
	fmt
			Runs terraform format updating the needed files.
	validate
			Runs fmt target and terraform validate.
	clean
			Clean saved plans and logs.

```


## TODO:

### Missing pieces:

#### Database VM
- Set the frontend/dashboard IP in the Prometheus configuration.
- (Bonus) Use the RDMS database to store the state for the grafana service.
- (Bonus) Backup the database to an S3 bucket (on daily schedule.)

#### Dashboard VM
- A container running a dashboard service (Grafana or alike.)
- (Bonus) A simple dashboard displaying the metrics collected by Prometheus + node-exporter.

#### CI/CD
- Configure a CI/CD pipeline using GitLab to lint the terraform configuration files and the configuration tool’s playbook.
- (Bonus) Configure the CI/CD pipeline to configure the VMs on every commit pushed to the main branch.


### Can be improved:

#### At Bootstrap:
- Create a deployment token via the gitlab api.
- Use ansible-vault for storing the data in the git repository.
- Add a method to remove the s3 bucket and the key pair when terraform resources are destroyed.

#### At Deployment:
- The cloud-init process only runs the provided directives during the boot cycle the first time that the instance is 
launched. So if there is an error in the `user_data` script, the instance would not be re provisioned even after fix
the error. Fortunately there is method to run the `user_data` script with every restart,
see: [knowledge cente article](https://repost.aws/en/knowledge-center/execute-user-data-ec2)
 

