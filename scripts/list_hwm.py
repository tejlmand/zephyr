#!/usr/bin/env python3

# Copyright (c) 2023 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

import argparse
from pathlib import Path, PurePath
import pykwalify.core
import sys
import yaml

SOC_METADATA_SCHEMA = '''
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
          family:
            required: false
            type: str
            desc: SoC family of the SoC.
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

ARCH_METADATA_SCHEMA = '''
## A pykwalify schema for basic validation of the structure of a
## metadata YAML file.
##
# The archs.yml file is a simple list of key value pairs containing architectures
# and their location which is used by the build system.
type: map
mapping:
  archs:
    required: true
    type: seq
    sequence:
      - type: map
        mapping:
          name:
            required: false
            type: str
            desc: Name of the arch
          folder:
            required: true
            type: str
            desc: Location of the arch implementation relative to the archs.yml file.
          comment:
            required: false
            type: str
            desc: Free form comment with extra information regarding the arch.
'''

SOCS_YML_PATH = PurePath('soc/socs.yml')
ARCHS_YML_PATH = PurePath('arch/archs.yml')

soc_schema = yaml.safe_load(SOC_METADATA_SCHEMA)
arch_schema = yaml.safe_load(ARCH_METADATA_SCHEMA)


def find_v2_archs(args):
    ret = {'archs': []}
    for root in args.arch_roots:
        archs_yml = root / ARCHS_YML_PATH

        if Path(archs_yml).is_file():
            with Path(archs_yml).open('r') as f:
                archs = yaml.safe_load(f.read())

            try:
                pykwalify.core.Core(source_data=archs, schema_data=arch_schema).validate()
            except pykwalify.errors.SchemaError as e:
                sys.exit('ERROR: Malformed "build" section in file: {}\n{}'
                         .format(archs_yml.as_posix(), e))

            if args.arch is not None and args.series is not None:
                archs = {'archs': list(filter(
                    lambda arch: arch.get('name') == args.arch, archs['archs']))}
            for arch in archs['archs']:
                arch.update({'folder': root / 'arch' / arch['folder']})
                arch.update({'hwm': 'v2'})
                arch.update({'type': 'arch'})

            ret['archs'].extend(archs['archs'])

    return ret


def find_v2_socs(args):
    ret = {'socs': []}
    for root in args.soc_roots:
        socs_yml = root / SOCS_YML_PATH

        if Path(socs_yml).is_file():
            with Path(socs_yml).open('r') as f:
                socs = yaml.safe_load(f.read())

            try:
                pykwalify.core.Core(source_data=socs, schema_data=soc_schema).validate()
            except pykwalify.errors.SchemaError as e:
                sys.exit('ERROR: Malformed "build" section in file: {}\n{}'
                         .format(socs_yml.as_posix(), e))

            if any([args.soc, args.soc_series, args.soc_family]):
                socs = {'socs': list(filter(
                    lambda soc: soc.get('name', '') == args.soc or
                        soc.get('series', '') == args.soc_series or
                        soc.get('family', '') == args.soc_family,
                        socs['socs']))}
            for soc in socs['socs']:
                soc.update({'folder': root / 'soc' / soc['folder']})
                soc.update({'hwm': 'v2'})
                soc.update({'type': 'soc'})

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
    parser.add_argument("--soc", default=None, help='lookup the specific soc')
    parser.add_argument("--soc-series", default=None, help='lookup the specific soc series')
    parser.add_argument("--soc-family", default=None, help='lookup the specific family')
    parser.add_argument("--socs", action='store_true', help='lookup all socs')
    parser.add_argument("--arch-root", dest='arch_roots', default=[],
                        type=Path, action='append',
                        help='add a arch root, may be given more than once')
    parser.add_argument("--arch", default=None, help='lookup the specific arch')
    parser.add_argument("--archs", action='store_true', help='lookup all archs')
    parser.add_argument("--format", default=default_fmt,
                        help='''Format string to use to list each soc.''')
    parser.add_argument("--cmakeformat", default=None,
                        help='''CMake format string to use to list each arch/soc.''')


def dump_v2_archs(args):
    archs = find_v2_archs(args)

    for arch in archs['archs']:
        if args.cmakeformat is not None:
            info = args.cmakeformat.format(
                TYPE='TYPE;' + arch['type'],
                NAME='NAME;' + arch['name'],
                DIR='DIR;' + str(arch['folder']),
                HWM='HWM;' + arch['hwm'],
                # Below is non exising for arch but is defined here to support
                # common formatting string.
                SERIES='',
                FAMILY='',
                ARCH='',
                VENDOR=''
            )
        else:
            info = args.format.format(
                type=arch.get('type'),
                name=arch.get('name'),
                dir=arch.get('folder'),
                hwm=arch.get('hwm'),
                # Below is non exising for arch but is defined here to support
                # common formatting string.
                series='',
                family='',
                arch='',
                vendor=''
            )

        print(info)


def dump_v2_socs(args):
    socs = find_v2_socs(args)

    for soc in socs['socs']:
        if args.cmakeformat is not None:
            info = args.cmakeformat.format(
                TYPE='TYPE;' + soc['type'],
                NAME='NAME;' + soc.get('name', 'NOTFOUND'),
                SERIES='SERIES;' + soc.get('series', 'NOTFOUND'),
                FAMILY='FAMILY;' + soc.get('family', 'NOTFOUND'),
                DIR='DIR;' + str(soc['folder']),
                ARCH='ARCH;' + soc.get('arch', 'NOTFOUND'),
                VENDOR='VENDOR;' + soc.get('vendor', 'NOTFOUND'),
                HWM='HWM;' + soc['hwm']
            )
        else:
            info = args.format.format(
                type=soc.get('type'),
                name=soc.get('name'),
                series=soc.get('series'),
                family=soc.get('family'),
                dir=soc.get('folder'),
                arch=soc.get('arch'),
                vendor=soc.get('vendor'),
                hwm=soc.get('hwm')
            )

        print(info)


if __name__ == '__main__':
    args = parse_args()
    if any([args.socs, args.soc, args.soc_series, args.soc_family]):
        dump_v2_socs(args)
    if args.archs or args.arch is not None:
        dump_v2_archs(args)
