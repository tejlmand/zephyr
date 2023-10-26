#!/usr/bin/env python3

# Copyright (c) 2023 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

import argparse
from pathlib import Path, PurePath
import pykwalify.core
import sys
import yaml

METADATA_SCHEMA = '''
## A pykwalify schema for basic validation of the structure of a
## metadata YAML file.
##
# The socs.yml file is a simple list of key value pairs containing SoCs
# and their location which is used by the build system.
type: map
mapping:
  socs:
    required: true
    type: seq
    sequence:
      - type: map
        mapping:
          name:
            required: false
            type: str
            desc: Name of the SoC
          series:
            required: false
            type: str
            desc: SoC series of the SoC.
          folder:
            required: true
            type: str
            desc: Location of the SoC implementation relative to the socs.yml file.
          vendor:
            required: false
            type: str
            desc: SoC series of the SoC.
                  This field is of informational use and can be used for filtering of SoCs.
          arch:
            required: false
            type: str
            desc: architecture of the SoC on a single-core SoC, for a multi-core SoC with
                  mixed architectures, the value mixed can be used.
                  This field is of informational use and can be used for filtering of SoCs.
          comment:
            required: false
            type: str
            desc: Free form comment with extra information regarding the SoC.
'''

SOCS_YML_PATH = PurePath('soc/socs.yml')

schema = yaml.safe_load(METADATA_SCHEMA)


def find_v2_socs(args):
    ret = {'socs': []}
    for root in args.soc_roots:
        socs_yml = root / SOCS_YML_PATH

        if Path(socs_yml).is_file():
            with Path(socs_yml).open('r') as f:
                socs = yaml.safe_load(f.read())

            try:
                pykwalify.core.Core(source_data=socs, schema_data=schema).validate()
            except pykwalify.errors.SchemaError as e:
                sys.exit('ERROR: Malformed "build" section in file: {}\n{}'
                         .format(socs_yml.as_posix(), e))

            if args.soc is not None and args.series is not None:
                socs = {'socs': list(filter(
                    lambda soc: soc.get('name') == args.soc or soc.get('series') == args.series,
                        socs['socs']))}
            for soc in socs['socs']:
                soc.update({'folder': root / 'soc' / soc['folder']})
                soc.update({'hwm': 'v2'})

            ret['socs'].extend(socs['socs'])

    return ret


def parse_args():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    add_args(parser)
    return parser.parse_args()


def add_args(parser):
    default_fmt = '{name}'

    parser.add_argument("--soc-root", dest='soc_roots', default=[],
                        type=Path, action='append',
                        help='add a SoC root, may be given more than once')
    parser.add_argument("--soc", dest='soc', default=None,
                        help='lookup the specific soc')
    parser.add_argument("--series", dest='series', default=None,
                        help='lookup the specific soc series')
    parser.add_argument("--format", default=default_fmt,
                        help='''Format string to use to list each soc.''')


def dump_v2_socs(args):
    socs = find_v2_socs(args)

    for soc in socs['socs']:
        info = args.format.format(
            name=soc.get('name'),
            series=soc.get('series'),
            dir=soc.get('folder'),
            arch=soc.get('arch'),
            vendor=soc.get('vendor'),
            hwm=soc.get('hwm')
        )

        print(info)


if __name__ == '__main__':
    args = parse_args()
    dump_v2_socs(args)
