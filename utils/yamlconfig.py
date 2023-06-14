#!/usr/bin/env python3
"""
"""
import logging
import sys
import yaml
import json
import logging

from pathlib import Path


def yamlconfig(filepath: Path, config_key: str) -> str:
    """

    :param filepath: Path:
    :param key: String:
    :return: String:
    """
    config = yaml.safe_load(filepath.read_text())
    keys = config_key.split(".")
    value = config

    for key in keys:
        value = value[key]

    if not isinstance(value, str):
        return json.dumps(value)

    return value


def main() -> int:
    """
    Simple main function to interface with the yamlconfig function.
    :return: Int: The return value is a valid POSIX exit code.
    """
    logging.basicConfig(format=f'%(asctime)s:{sys.argv[0]}:%(message)s')
    # TODO: Use argparse to get the argument values.

    errors = []
    filepath = None
    key = None

    try:
        filename = sys.argv[1]
    except IndexError as exe:
        errors.append(logging.error("'filepath' for the configuration file must be provided."))
    else:
        filepath = Path(filename)
        if not filepath.exists():
            errors.append(logging.error("filepath does not exist"))
        elif not filepath.is_file():
            errors.append(logging.error("filepath must be a file"))

    if len(sys.argv) < 3:
        errors.append(logging.error("A configuration Key must be provided."))
    elif len(sys.argv) > 3:
        errors.append(logging.error("Only one configuration Key must be provided."))
    else:
        key = sys.argv[2]

    if filepath and filepath.exists() and key:
        try:
            result = yamlconfig(filepath, key)
        except KeyError:
            errors.append(logging.error("Key '%s' not found.", key))
        else:
            print(result)

    # Return 0 if there was no error or the number of errors as exit code.
    return len(errors)


if __name__ == "__main__":
    sys.exit(main())
