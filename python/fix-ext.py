import sys
import signal
import logging
import coloredlogs
import argparse
import magic
import mimetypes
from pathlib import Path


def handle_sigint(signum, frame):
    # runs when CTRL+C is pressed and exists with code 1
    log.warning('\n\nprocess interrupted by SIGINT\n')
    sys.exit(1)


def build_parser():
    # create and configure the argument parser needed for the script
    parser = argparse.ArgumentParser(description="fix the extension of each file in a specified directory")
    parser.add_argument("-D", "--dry-run", action="store_true", help="simulate changes without renaming files")

    # group of exclusive parameters
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-d", "--directory", type=str, metavar="", help="directory path with files to process (is exclusive to --file)")
    group.add_argument("-f", "--file", nargs='+', type=str, metavar="", help="file o files path to processa (is exclusive to --directory)")

    args = parser.parse_args()

    return args


def get_file_extension(fpath):
    # detect the MIME type of aech file to obtain its file extension
    # detecting the actual MIME type of the file: '{fpath}'
    mime = magic.from_file(fpath, mime=True)
    #getting the standard extension from the MIMTE type: '{fpath}':'{mime}'
    extension = mimetypes.guess_extension(mime)

    return str(extension)


def process_files(files, dry_run):
    # process one or more files, pass them through Path() to convert them to Path objects, and
    # verify file integrity by checking that they exist and are regular files.
    log.debug("processing the list of one or more files")

    for file in files:
        fpath = Path(file)

        # checking if '{fpath}' is a files and exists
        if not (fpath.exists() and fpath.is_file()):
            log.error(f"'{fpath}' is not a valid file or does not exist")
            continue

        # it gets the file extension based on the MIME type; otherwise, if it returns None, the file is skipped
        file_extension = get_file_extension(fpath)

        if file_extension is None:
            log.warning(f"it can't detect the '{fpath}' file extension")
            continue

        # it generates the new file name with the corresponding extension, but if both files have the same name, it is skipped
        fix_extension = fpath.with_suffix(file_extension)

        if fpath == fix_extension:
            print(f"\033[34mSKIPPING\033[00m {fpath} -> {fix_extension}")
            continue

        # checking if the dry run mode is used
        if dry_run:
            print(f"\033[33mDRYRUN\033[00m {fpath} -> {fix_extension}")
        else:
            try:
                log.info(f"renamed {fpath} to {fix_extension}")
                fpath.rename(fix_extension)
            except Exception as e:
                log.error(f"renaming {fpath}: {e}")


if __name__ == '__main__':
    # logging is set to DEBUG, coloredlogs defines the output format and level
    log = logging.getLogger()
    log.setLevel(logging.DEBUG)
    coloredlogs.install(level='INFO', logger=log, fmt="%(levelname)s %(message)s")

    # set SIGINT to capture CTRL+C and display a message
    signal.signal(signal.SIGINT, handle_sigint)

    # instantiate the argument parser
    args = build_parser()

    if args.file:
        # using the -f / --file flag
        files = args.file

    elif args.directory:
        # using the -d / --directory flag
        # iterating over the '{args.directory}' directory and retrieving only the files at the first level
        files = [ file for file in Path(args.directory).iterdir() if file.is_file() ]

    # process one or more files
    process_files(files, args.dry_run)

