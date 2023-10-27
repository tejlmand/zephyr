#!/usr/bin/env python3

# Copyright (c) 2020 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

import argparse
from collections import defaultdict
import itertools
from pathlib import Path, PurePath
import pykwalify.core
from typing import NamedTuple
import sys
import yaml

METADATA_SCHEMA = '''
## A pykwalify schema for basic validation of the structure of a
## metadata YAML file.
##
# The boards.yml file is a simple list of key value pairs containing boards
# and their location which is used by the build system.
type: map
mapping:
  boards:
    required: true
    type: seq
    sequence:
      - type: map
        mapping:
          name:
            required: true
            type: str
            desc: Name of the board
          folder:
            required: true
            type: str
            desc: Location of the board implementation relative to the boards.yml file.
          vendor:
            required: false
            type: str
            desc: SoC family of the SoC on the board.
                  This field is of informational use and can be used for filtering of boards.
          family:
            required: false
            type: str
            desc: SoC family of the SoC on the board.
                  This field is of informational use and can be used for filtering of boards.
          arch:
            required: false
            type: str
            desc: architecture of the SoC on a single SoC board, for a board with multiple SoCs
                  or multi-core SoC with mixed architectures, the value mixed can be used.
                  This field is of informational use and can be used for filtering of boards.
          comment:
            required: false
            type: str
            desc: Free form comment with extra information regarding the board.
'''

BOARD_METADATA_SCHEMA = '''
## A pykwalify schema for basic validation of the structure of a
## metadata YAML file.
##
# The board.yml file is a simple list of key value pairs containing board
# information like: name, vendor, arch, cpusets.
type: map
mapping:
  board:
    required: true
    type: map
    mapping:
      name:
        required: true
        type: str
        desc: Name of the board
      vendor:
        required: false
        type: str
        desc: SoC family of the SoC on the board.
      family:
        required: false
        type: str
        desc: SoC family of the SoC on the board.
      arch:
        required: false
        type: str
        desc: architecture of the SoC on a single SoC board, for a board with multiple SoCs
              or multi-core SoC with mixed architectures, the value mixed can be used.
      revision:
        required: false
        type: map
        mapping:
          format:
            required: true
            type: str
            enum:
              ["major.minor.patch", "letter", "number", "fuzzy", "custom"]
          default:
            required: true
            type: str
          revisions:
            required: true
            type: seq
            sequence:
              - type: map
                mapping:
                  name:
                    required: true
                    type: str
      cpusets:
        required: false
        type: map
        desc: cpusets for the board when board contains multicore SoC or multiple
              SoCs. If the cpuset is only valid for a specific board revision, then
              the board revision cpuset should be used instead
        mapping:
          default:
            required: true
            type: str
          names:
            required: true
            type: seq
            sequence:
             - type: str
               required: true
      comment:
        required: false
        type: str
        desc: Free form comment with extra information regarding the board.
'''
BOARDS_YML_PATH = PurePath('boards/boards.yml')
BOARD_YML = PurePath('board.yml')

schema = yaml.safe_load(METADATA_SCHEMA)
board_schema = yaml.safe_load(BOARD_METADATA_SCHEMA)

#
# This is shared code between the build system's 'boards' target
# and the 'west boards' extension command. If you change it, make
# sure to test both ways it can be used.
#
# (It's done this way to keep west optional, making it possible to run
# 'ninja boards' in a build directory without west installed.)
#

class Board(NamedTuple):
    name: str
    arch: str
    dir: Path
    hwm: str

def board_key(board):
    return board.name

def find_arch2boards(args):
    arch2board_set = find_arch2board_set(args)
    return {arch: sorted(arch2board_set[arch], key=board_key)
            for arch in arch2board_set}

def find_boards(args):
    return sorted(itertools.chain(*find_arch2board_set(args).values()),
                  key=board_key)

def find_arch2board_set(args):
    arches = sorted(find_arches(args))
    ret = defaultdict(set)

    for root in args.board_roots:
        for arch, boards in find_arch2board_set_in(root, arches).items():
            if args.board is not None:
                ret[arch] |= {b for b in boards if b.name == args.board}
            else:
                ret[arch] |= boards

    return ret

def find_arches(args):
    arch_set = set()

    for root in args.arch_roots:
        arch_set |= find_arches_in(root)

    return arch_set

def find_arches_in(root):
    ret = set()
    arch = root / 'arch'
    common = arch / 'common'

    if not arch.is_dir():
        return ret

    for maybe_arch in arch.iterdir():
        if not maybe_arch.is_dir() or maybe_arch == common:
            continue
        ret.add(maybe_arch.name)

    return ret

def find_arch2board_set_in(root, arches):
    ret = defaultdict(set)
    boards = root / 'boards'

    for arch in arches:
        if not (boards / arch).is_dir():
            continue

        for maybe_board in (boards / arch).iterdir():
            if not maybe_board.is_dir():
                continue
            for maybe_defconfig in maybe_board.iterdir():
                file_name = maybe_defconfig.name
                if file_name.endswith('_defconfig'):
                    board_name = file_name[:-len('_defconfig')]
                    ret[arch].add(Board(board_name, arch, maybe_board, 'v1'))

    return ret

def find_v2_boards(args):
    ret = {'boards': []}
    for root in args.board_roots:
        boards_yml = root / BOARDS_YML_PATH

        if Path(boards_yml).is_file():
            with Path(boards_yml).open('r') as f:
                boards = yaml.safe_load(f.read())

            try:
                pykwalify.core.Core(source_data=boards, schema_data=schema).validate()
            except pykwalify.errors.SchemaError as e:
                sys.exit('ERROR: Malformed "build" section in file: {}\n{}'
                         .format(boards_yml.as_posix(), e))

            if args.board is not None:
                boards = {'boards': list(filter(
                    lambda board: board['name'] == args.board, boards['boards']))}
            for board in boards['boards']:
                board.update({'folder': root / 'boards' / board['folder']})
                board.update({'hwm': 'v2'})

            ret['boards'].extend(boards['boards'])

    return ret

def parse_args():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    add_args(parser)
    return parser.parse_args()

def add_args(parser):
    # Remember to update west-completion.bash if you add or remove
    # flags
    default_fmt = '{name}'

    parser.add_argument("--arch-root", dest='arch_roots', default=[],
                        type=Path, action='append',
                        help='add an architecture root, may be given more than once')
    parser.add_argument("--board-root", dest='board_roots', default=[],
                        type=Path, action='append',
                        help='add a board root, may be given more than once')
    parser.add_argument("--board", dest='board', default=None,
                        help='lookup the specific board, fail if not found')
    parser.add_argument("--format", default=default_fmt,
                        help='''Format string to use to list each board;
                                see FORMAT STRINGS below.''')
    parser.add_argument("--cmakeformat", default=None,
                        help='''CMake Format string to use to list each board''')

def dump_v2_boards(args):
    boards = find_v2_boards(args)

    for board in boards['boards']:
        board_yml = board['folder'] / BOARD_YML

        if Path(board_yml).is_file():
            with Path(board_yml).open('r') as f:
                b = yaml.safe_load(f.read())

            try:
                pykwalify.core.Core(source_data=b, schema_data=board_schema).validate()
            except pykwalify.errors.SchemaError as e:
                sys.exit('ERROR: Malformed "build" section in file: {}\n{}'
                         .format(board_yml.as_posix(), e))
            b['board'].update({'folder': board['folder']})
            b['board'].update({'hwm': board['hwm']})
            board = b['board']

        if args.cmakeformat is not None:
            board_rev = board.get('revision', {})
            board_cpu = board.get('cpusets', {})
            info = args.cmakeformat.format(
                NAME='NAME;' + board['name'],
                DIR='DIR;' + str(board['folder']),
                ARCH='ARCH;' + board.get('arch', 'NOTFOUND'),
                VENDOR='VENDOR;' + board.get('vendor', 'NOTFOUND'),
                HWM='HWM;' + board['hwm'],
                REVISION_DEFAULT='REVISION_DEFAULT;' + board_rev.get('default', 'NOTFOUND'),
                REVISION_FORMAT='REVISION_FORMAT;' + board_rev.get('format', 'NOTFOUND'),
                REVISIONS='REVISIONS;' + ';'.join(
                          [x['name'] for x in board_rev.get('revisions', [{'name': 'NOTFOUND'}])]),
                CPUSET_DEFAULT='CPUSET_DEFAULT;' + board_cpu.get('default', 'NOTFOUND'),
                CPUSETS='CPUSETS;' + ';'.join(board_cpu.get('names', ['NOTFOUND']))
            )
        else:
            info = args.format.format(
                name=board['name'],
                dir=board['folder'],
                arch=board['arch'],
                vendor=board['vendor'],
                hwm=board['hwm']
            )
        print(info)

def dump_boards(args):
    arch2boards = find_arch2boards(args)
    for arch, boards in arch2boards.items():
        if args.format is None:
            print(f'{arch}:')
        for board in boards:
            if args.cmakeformat is not None:
                info = args.cmakeformat.format(
                    NAME='NAME;' + board.name,
                    DIR='DIR;' + str(board.dir),
                    ARCH='ARCH;' + board.arch,
                    HWM='HWM;' + board.hwm,
                    VENDOR='VENDOR;NOTFOUND',
                    REVISION_DEFAULT='REVISION_DEFAULT;NOTFOUND',
                    REVISION_FORMAT='REVISION_FORMAT;NOTFOUND',
                    REVISIONS='REVISIONS;NOTFOUND',
                    CPUSET_DEFAULT='CPUSET_DEFAULT;NOTFOUND',
                    CPUSETS='CPUSETS;NOTFOUND',
                )
            else:
              info = args.format.format(
                  name=board.name,
                  arch=board.arch,
                  dir=board.dir,
                  hwm=board.hwm)
            print(info)

if __name__ == '__main__':
    args = parse_args()
    dump_boards(args)
    dump_v2_boards(args)
