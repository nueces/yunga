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
    Read the <filepath> yaml file and return the value for <config_key>.
    :param filepath: Path: yaml file
    :param config_key: String: key to be read. If it contains a dot, then it would be treated as an attribute.
    :return: String: A string containing a simple value or a json representation of the python object in any other case
        like list or dicts.

    Usage examples:

    # First lets create a simple yaml file
    >>> content = '''map:
    ...   name: fruits
    ...   items:
    ...     - apple
    ...     - orange
    ...     - tomato
    ...   amounts:
    ...     apple: 2
    ...     orange: 4
    ...     tomato: 6\
    '''

    # We need to create a Path like object to use in the body function.
    >>> from io import StringIO
    >>> file_path = StringIO(content)

    # Patch the read_text method and rewind the IOStream to simulate the same behaviour that the desired function.
    >>> file_path.read_text = lambda : file_path.read() if [file_path.seek(0)] else None

    # Now lets start with the examples
    >>> yamlconfig(file_path, 'map.name')
    'fruits'

    >>> yamlconfig(file_path, 'map.items')
    '["apple", "orange", "tomato"]'

    >>> yamlconfig(file_path, 'map.amounts')
    '{"apple": 2, "orange": 4, "tomato": 6}'

    >>> yamlconfig(file_path, 'map.amounts.tomato')
    '6'

    >>> yamlconfig(file_path, 'map.amounts.lemons')
    Traceback (most recent call last):
    ...
    KeyError: 'lemons'

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
    Main function to interface with the yamlconfig function.
    :return: Int: The return value is a valid POSIX exit code.


    # TODO: Write doctest
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
