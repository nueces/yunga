locals {
  filter = var.ami_id == null ? { name : var.ami_filter_name } : { image-id : var.ami_id }
}


data "aws_ami" "vm" {
  most_recent = true
  owners      = [var.ami_filter_owner_id]

  dynamic "filter" {
    for_each = local.filter
    content {
      name   = filter.key
      values = [filter.value]
    }
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


locals {
  ami_tags = {
    AMIId              = data.aws_ami.vm.image_id
    AMICreationDate    = data.aws_ami.vm.creation_date
    AMIDeprecationTime = data.aws_ami.vm.deprecation_time
    AMIDescription     = data.aws_ami.vm.description
  }

  # TODO: Set git_token variable as sensitive
  user_data = {
    templatefile = join("/", [path.module, "templates", "cloud-init-config.yml.tftpl"])
    variables = {
      project_public_key = file(join("/", [local.vault_path, "${local.configuration.keypair_name}.pub"]))
      git_username       = local.configuration.git.username
      git_token          = file(join("/", [local.vault_path, local.configuration.git.token_filename]))
      git_repository_url = local.configuration.git.repository_url
      project_name       = lower(local.configuration.project_name)
    }
  }
}


resource "aws_instance" "backend" {
  ami                         = data.aws_ami.vm.image_id
  instance_type               = lookup(var.instance_types, "backend")
  availability_zone           = local.defaults.availability_zone
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.public.id]
  associate_public_ip_address = false
  key_name                    = local.configuration.keypair_name

  user_data = templatefile(
    local.user_data.templatefile,
    merge(local.user_data.variables, { ansible_role = "backend" })
  )
  tags = merge(
    var.default_tags, local.ami_tags, {
      Name         = "${local.configuration.project_name} Backend Instance"
      Tier         = "backend"
      InstanceType = lookup(var.instance_types, "backend")
  })
}


resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.vm.image_id
  instance_type               = lookup(var.instance_types, "frontend")
  availability_zone           = local.defaults.availability_zone
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public.id]
  associate_public_ip_address = true
  key_name                    = local.configuration.keypair_name

  user_data = templatefile(
    local.user_data.templatefile,
    merge(local.user_data.variables, { ansible_role = "frontend" })
  )

  tags = merge(
    var.default_tags, local.ami_tags, {
      Name         = "${local.configuration.project_name} Frontend Instance"
      Tier         = "frontend"
      InstanceType = lookup(var.instance_types, "frontend")
  })
}


resource "aws_ebs_volume" "backend" {
  availability_zone = local.defaults.availability_zone
  size              = 2

  tags = merge(
    var.default_tags, {
      Name = "${local.configuration.project_name} Backend data storage volume"
  })
}


resource "aws_volume_attachment" "backend" {
  device_name                    = local.configuration.data_device_name
  volume_id                      = aws_ebs_volume.backend.id
  instance_id                    = aws_instance.backend.id
  stop_instance_before_detaching = true
}

##############################################################################
# Outputs
# TODO: outputs should be dynamically generated using a for aws_instance[*]
##############################################################################