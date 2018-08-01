#!/usr/bin/env python3

import argparse

def main():
    args = parse_args()

    object_files = args.object_files_as_csv.split(',')

    s = '#define NUM_KERNEL_OBJECT_FILES {}\n'.format(len(object_files))
    for i, item in enumerate(object_files):
        s += '#define KERNEL_OBJECT_FILE_{} {}\n'.format(i, item)

    with open(args.output_file, "w") as fp:
        fp.write(s)

def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument("-i", "--object-files-as-csv", required=True)
    parser.add_argument("-o", "--output-file", required=True)

    return parser.parse_args()

if __name__ == "__main__":
    main()
