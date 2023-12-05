#!/usr/bin/env python3

# Copyright (c) 2020 Nordic Semiconductor ASA
# SPDX-License-Identifier: Apache-2.0

import argparse
from collections import defaultdict
from dataclasses import dataclass, field
import itertools
from pathlib import Path
import pykwalify.core
import sys
from typing import List
import yaml
import list_hardware

BOARD_SCHEMA_PATH = str(Path(__file__).parent / 'schemas' / 'board-schema.yml')
with open(BOARD_SCHEMA_PATH, 'r') as f:
    board_schema = yaml.safe_load(f.read())

BOARD_YML = 'board.yml'

#
# This is shared code between the build system's 'boards' target
# and the 'west boards' extension command. If you change it, make
# sure to test both ways it can be used.
#
# (It's done this way to keep west optional, making it possible to run
# 'ninja boards' in a build directory without west installed.)
#


@dataclass
class Variant:
    name: str
    variants: List[str] = field(default_factory=list)

    @staticmethod
    def from_dict(variant):
        variants = []
        for v in variant.get('variants', []):
            variants.append(Variant.from_dict(v))
        return Variant(variant['name'], variants)


@dataclass
class Cpucluster:
    name: str
    variants: List[str] = field(default_factory=list)


@dataclass
class Soc:
    name: str
    cpuclusters: List[str] = field(default_factory=list)
    variants: List[str] = field(default_factory=list)

    @staticmethod
    def from_soc(soc, variants):
        if soc is None:
            return None
        if soc.cpuclusters:
            cpus = []
            for c in soc.cpuclusters:
                cpus.append(Cpucluster(c,
                            [Variant.from_dict(v) for v in variants if c == v['cpucluster']]
                ))
            return Soc(soc.name, cpuclusters=cpus)
        return Soc(soc.name, variants=[Variant.from_dict(v) for v in variants])


@dataclass(frozen=True)
class Board:
    name: str
    dir: Path
    hwm: str
    arch: str = None
    vendor: str = None
    revision_format: str = None
    revision_default: str = None
    revisions: List[str] = field(default_factory=list, compare=False)
    socs: List[Soc] = field(default_factory=list, compare=False)
    variants: List[str] = field(default_factory=list, compare=False)


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
                    ret[arch].add(Board(board_name, maybe_board, 'v1', arch=arch))

    return ret


def find_v2_boards(args):
    root_args = argparse.Namespace(**{'soc_roots': args.soc_roots})
    systems = list_hardware.find_v2_systems(root_args)

    boards = []
    board_files = []
    for root in args.board_roots:
        board_files.extend((root / 'boards').rglob(BOARD_YML))

    for board_yml in board_files:
        if board_yml.is_file():
            with board_yml.open('r') as f:
                b = yaml.safe_load(f.read())

            try:
                pykwalify.core.Core(source_data=b, schema_data=board_schema).validate()
            except pykwalify.errors.SchemaError as e:
                sys.exit('ERROR: Malformed "build" section in file: {}\n{}'
                         .format(board_yml.as_posix(), e))

            board = b['board']
            if args.board is not None:
                if board['name'] != args.board:
                    # Not the board we're looking for, ignore.
                    continue

            mutual_exclusive = {'socs', 'variants'}
            if len(mutual_exclusive - b['board'].keys()) < 1:
                sys.exit(f'ERROR: Malformed "board" section in file: {board_yml.as_posix()}\n'
                         f'{mutual_exclusive} are mutual exclusive at this level.')
            socs = [Soc.from_soc(systems.get_soc(s['name']), s.get('variants', []))
                    for s in board.get('socs', {})]

            board = Board(
                name=board['name'],
                dir=board_yml.parent,
                vendor=board['vendor'],
                socs=socs,
                variants=[Variant.from_dict(v) for v in board.get('variants', [])],
                hwm='v2',
            )
            boards.append(board)
    return boards


def parse_args():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    add_args(parser)
    add_args_formatting(parser)
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
    parser.add_argument("--soc-root", dest='soc_roots', default=[],
                        type=Path, action='append',
                        help='add a soc root, may be given more than once')
    parser.add_argument("--board", dest='board', default=None,
                        help='lookup the specific board, fail if not found')


def add_args_formatting(parser):
    parser.add_argument("--cmakeformat", default=None,
                        help='''CMake Format string to use to list each board''')


def variant_v2_identifiers(variant, identifier):
    identifiers = [identifier + '/' + variant.name]
    for v in variant.variants:
        identifiers.append(variant_v2_identifiers(v, identifier + '/' + variant.name))
    return identifiers


def board_v2_identifiers(board):
    identifiers = []

    for s in board.socs:
        if s.cpuclusters:
            for c in s.cpuclusters:
                id_str = board.name + '/' + s.name + '/' + c.name
                identifiers.append(id_str)
                for v in c.variants:
                    identifiers.extend(variant_v2_identifiers(v, id_str))
        else:
            id_str = board.name + '/' + s.name
            identifiers.append(id_str)
            for v in s.variants:
                identifiers.extend(variant_v2_identifiers(v, id_str))

    if not board.socs:
        identifiers.append(board.name)

    for v in board.variants:
        identifiers.extend(variant_v2_identifiers(v, board.name))
    return identifiers


def dump_v2_boards(args):
    boards = find_v2_boards(args)

    for b in boards:
        identifiers = board_v2_identifiers(b)
        if args.cmakeformat is not None:
            notfound = lambda x: x or 'NOTFOUND'
            info = args.cmakeformat.format(
                NAME='NAME;' + b.name,
                DIR='DIR;' + str(b.dir),
                VENDOR='VENDOR;' + notfound(b.vendor),
                HWM='HWM;' + b.hwm,
                REVISION_DEFAULT='REVISION_DEFAULT;' + notfound(b.revision_default),
                REVISION_FORMAT='REVISION_FORMAT;' + notfound(b.revision_format),
                REVISIONS='REVISIONS;' + ';'.join(
                          [x.name for x in b.revisions]),
                IDENTIFIERS='IDENTIFIERS;' + ';'.join(identifiers)
            )
            print(info)
        else:
            print(f'{b.name}')


def dump_boards(args):
    arch2boards = find_arch2boards(args)
    for arch, boards in arch2boards.items():
        if args.cmakeformat is None:
            print(f'{arch}:')
        for board in boards:
            if args.cmakeformat is not None:
                info = args.cmakeformat.format(
                    NAME='NAME;' + board.name,
                    DIR='DIR;' + str(board.dir),
                    HWM='HWM;' + board.hwm,
                    VENDOR='VENDOR;NOTFOUND',
                    REVISION_DEFAULT='REVISION_DEFAULT;NOTFOUND',
                    REVISION_FORMAT='REVISION_FORMAT;NOTFOUND',
                    REVISIONS='REVISIONS;NOTFOUND',
                    VARIANT_DEFAULT='VARIANT_DEFAULT;NOTFOUND',
                    IDENTIFIERS='IDENTIFIERS;'
                )
                print(info)
            else:
                print(f'  {board.name}')


if __name__ == '__main__':
    args = parse_args()
    dump_boards(args)
    dump_v2_boards(args)
