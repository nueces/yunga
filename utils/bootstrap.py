"""
Bootstrap tasks for creating basic resources need to use terraform and ansible.
"""
import logging
import os.path
import stat
import sys
from datetime import datetime
from pathlib import Path

import boto3
import yaml
from botocore.exceptions import ClientError

# Basic settings
# file has to be present in the project root directory.
# FIXME: use argparse to get the configuration file as parameter.
PROJECT_CONFIGURATION_FILE = "configuration.yml"

TASK = os.path.splitext(os.path.basename(__file__))[0]
BASE_DIR = Path(os.path.dirname(__file__)).parent


logging.basicConfig(
    level=logging.INFO,
    format=f"%(asctime)s: %(levelname)s: {TASK}: %(message)s",
    datefmt="%Y-%m-%d %H%M%S",
    handlers=[
        logging.FileHandler(BASE_DIR.joinpath("logs", f"{TASK}.log")),
        logging.StreamHandler(),
    ],
)
LOGGER = logging.getLogger(TASK)


def create_bucket(bucket_name: str, region_name: str, enable_versioning: bool = True) -> bool:
    """
    Create an S3 bucket in a specified region.

    :param bucket_name: String, Bucket to create.
    :param region_name: String, Region to create bucket in, e.g., 'us-west-2'.
    :param enable_versioning: Bool, default True.
    :return: Bool, True if bucket created or if it already exists, else False.
    """
    result = False
    s3_client = boto3.client("s3", region_name=region_name)

    try:
        s3_client.create_bucket(
            Bucket=bucket_name,
            CreateBucketConfiguration={"LocationConstraint": region_name},
        )
    except ClientError as error:
        try:
            result = error.response["Error"]["Code"] == "BucketAlreadyOwnedByYou"
            if result:
                LOGGER.info("BucketAlreadyOwnedByYou: Bucket already exist")
            else:
                LOGGER.error(error)
        except KeyError:
            LOGGER.error(error)
    else:
        result = True

    if result and enable_versioning:
        try:
            response = s3_client.get_bucket_versioning(Bucket=bucket_name)
        except ClientError as error:
            LOGGER.error(error)
            result = False
        else:
            status = response.get("Status", "NotSet")
            if status == "Enabled":
                LOGGER.info("Versioning on bucket %s already enabled", bucket_name)
            elif status in ("NotSet", "Disabled"):
                LOGGER.info("Enabling versioning on bucket %s. Previous versioning status: %s", bucket_name, status)
                try:
                    response = s3_client.put_bucket_versioning(
                        Bucket=bucket_name, VersioningConfiguration={"Status": "Enabled"}
                    )
                except ClientError as error:
                    LOGGER.error(error)
                    LOGGER.error(response)
                    result = False

    return result


def create_key_pair(keypair_name: str, parent_path: Path, region_name: str) -> bool:
    """
    Create a Keypair in a specified region, and store the KeyMaterial/PrivateKey in the parent_path location.

    :param keypair_name: String, resource name to be created.
    :param parent_path: Path, where the new key would be storage in the local machine.
    :param region_name: String, Region to create bucket in, e.g., 'us-west-2'.
    :return: Bool, True if bucket created or if it already exists, else False.
    """
    result = False
    ec2_client = boto3.client("ec2", region_name=region_name)
    file_path = parent_path.joinpath(f"{keypair_name}.pem")

    st_mode = parent_path.stat().st_mode
    # Check if a directory and with  permissions for reading, writing and execute only for the owner user.
    if st_mode != stat.S_IFDIR | stat.S_IRWXU:
        LOGGER.warning(
            "Current permissions for the vault directory '%s' are considered insecure '%s'",
            parent_path,
            stat.filemode(st_mode),
        )
        LOGGER.info(
            "Updating permissions for the vault directory '%s' to '%s'",
            parent_path,
            stat.filemode(stat.S_IFDIR | stat.S_IRWXU),
        )
        parent_path.chmod(stat.S_IFDIR | stat.S_IRWXU)
    try:
        response = ec2_client.create_key_pair(KeyName=keypair_name, KeyType="rsa", KeyFormat="pem")
    except ClientError as error:
        try:
            result = error.response["Error"]["Code"] == "InvalidKeyPair.Duplicate"
            if result:
                LOGGER.warning("keypair '%s' already exist.", keypair_name)
                result = file_path.exists()
                if not result:
                    LOGGER.error("Keypair is not present in the Vault location: %s", parent_path)
            else:
                LOGGER.error(error)
        except KeyError:
            LOGGER.error(error)
    else:
        if file_path.exists():
            # Don't override the private key in case it exist. But create a backup of the existing file.
            backup_time = datetime.now().strftime("%Y%m%d-%H%M%S")
            backup_path = parent_path.joinpath(f"{keypair_name}.pem-{backup_time}.bck")
            LOGGER.warning("key file '%s' already exist.", file_path)
            LOGGER.info("Creating backup '%s'.", backup_path)
            file_path.rename(backup_path)

        LOGGER.info("Saving private key to '%s'", file_path)
        # This should fail in case the file still exist.
        with file_path.open("x") as fdk:
            file_path.chmod(stat.S_IWUSR | stat.S_IRUSR)
            result = bool(fdk.write(response["KeyMaterial"]))

    return result


def create_public_key(keypair_name: str, parent_path: Path, region_name: str) -> bool:
    """
    Create a Public key from a Keypair in the parent_path location.
    if the key exist in the parent_path location, replace the content.

    :param keypair_name: String, resource name to be created.
    :param parent_path: Path, where the new key would be storage in the local machine.
    :param region_name: String, Region to create bucket in, e.g., 'us-west-2'.
    :return: Bool, True if bucket created or if it already exists, else False.
    """
    result = False
    ec2_client = boto3.client("ec2", region_name=region_name)
    file_path = parent_path.joinpath(f"{keypair_name}.pub")

    try:
        response = ec2_client.describe_key_pairs(KeyNames=[keypair_name], IncludePublicKey=True)
    except ClientError as error:
        LOGGER.error(error)
    else:
        LOGGER.info("Saving public key to '%s'", file_path)
        # If the file exist truncate the content before writing.
        with file_path.open("w") as fdk:
            result = bool(fdk.write(response["KeyPairs"][0]["PublicKey"]))

    return result


def main(project_basedir: Path, config_filename: str) -> int:
    """
    :return: exit status code. 0 Success, 1 Fail.
    """
    success = []

    LOGGER.info("Starting task")

    # Configuration values
    with project_basedir.joinpath(config_filename).open("r") as fdc:
        config = yaml.safe_load(fdc)

    region = config.get("aws_region")
    key_name = config.get("keypair_name")
    vault_path = project_basedir.joinpath(config.get("vault_path"))

    sts_client = boto3.client("sts", region_name=region)
    account_id = sts_client.get_caller_identity().get("Account")
    # TODO: Compliance. Validate name convention.
    bucket_name = f"{account_id}-{region}-{config['terraform']['backend_bucket']}"

    LOGGER.info("Creating bucket: %s", bucket_name)
    success.append(create_bucket(bucket_name, region))

    LOGGER.info("Creating keypair: %s", key_name)
    success.append(create_key_pair(key_name, vault_path, region))

    LOGGER.info("Creating public key for keypair: %s", key_name)
    success.append(create_public_key(key_name, vault_path, region))

    if not all(success):
        LOGGER.error("Some errors occurs during the bootstrap process, please review the logs for more details.")

    LOGGER.info("Finish")
    # POSIX standard status code
    return 0 if all(success) else 1


if __name__ == "__main__":
    sys.exit(main(BASE_DIR, PROJECT_CONFIGURATION_FILE))
