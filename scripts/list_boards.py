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
          folder:
            required: true
            type: str
          vendor:
            required: false
            type: str
          family:
            required: false
            type: str
          arch:
            required: false
            type: str
          comment:
            required: false
            type: str
'''

BOARDS_YML_PATH = PurePath('boards/v2/boards.yml')

schema = yaml.safe_load(METADATA_SCHEMA)

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
                    ret[arch].add(Board(board_name, arch, maybe_board))

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
                board.update({'folder': root / board['folder']})

            ret['boards'].extend(boards['boards'])

    return ret

def parse_args():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    add_args(parser)
    return parser.parse_args()

def add_args(parser):
    # Remember to update west-completion.bash if you add or remove
    # flags
    parser.add_argument("--arch-root", dest='arch_roots', default=[],
                        type=Path, action='append',
                        help='add an architecture root, may be given more than once')
    parser.add_argument("--board-root", dest='board_roots', default=[],
                        type=Path, action='append',
                        help='add a board root, may be given more than once')
    parser.add_argument("--board", dest='board', default=None,
                        help='lookup the specific board, fail if not found')
    parser.add_argument("--format", type=str,
                        help='format string to use when printing board details.')

def dump_v2_boards(args):
    format_str = '    {name}'if args.format is None else args.format

    boards = find_v2_boards(args)
    if args.format is None:
        print('v2 boards:')

    for board in boards['boards']:
        info = format_str.format(
            name=board['name'],
            folder=board['folder'],
            arch=board['arch'],
            vendor=board['vendor'])

        print(info)

def dump_boards(args):
    format_str = '    {name}'if args.format is None else args.format

    arch2boards = find_arch2boards(args)
    for arch, boards in arch2boards.items():
        if args.format is None:
            print(f'{arch}:')
        for board in boards:
            info = format_str.format(
                name=board.name,
                arch=board.arch,
                folder=board.dir)
            print(info)

if __name__ == '__main__':
    args = parse_args()
    dump_v2_boards(args)
    dump_boards(args)
