#!/usr/bin/env python3
"""
"""
import logging
import sys
import yaml
import json
import logging

from pathlib import Path


def yamlconfig(filepath:Path, config_key: str) -> str:
    """

    :param filepath: Path:
    :param key: String:
    :return: String:
    """
    config = yaml.safe_load(filepath.read_text())
    keys = config_key.split(".")
    value = config

    for key in keys:
        try:
            value = value.get(key, None)
        except AttributeError as exe:
            raise AttributeError("Key '%s' not found", key)

    if isinstance(value, dict):
        return json.dumps(value)

    return value

def main() -> int:
    errors = []
    try:
        filename = sys.argv[1]
    except KeyError as exe:
        errors.append(logging.error("'filepath' for the configuration file must be provided."))
    else:
        filepath = Path(filename)
        if not filepath.exists():
            errors.append(logging.error("filepath does not exist"))

        if len(sys.argv) < 3:
            errors.append(logging.error("A configuration Key must be provided."))
        elif len(sys.argv) > 3:
            errors.append(logging.error("Only one configuration Key must be provided."))
        else:
            key = sys.argv[2]
            result = yamlconfig(filepath, key)
            if not result:
                errors.append(logging.error("Key '%s' not found.", key))
            else:
                print(result)

    return 0 if not any(errors) else 1


if __name__ == "__main__":
    sys.exit(main())