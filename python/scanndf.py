import sys
import argparse
import hashlib
import signal
import subprocess
from pathlib import Path

# script version
VERSION = '5.0.0'

# color list
red = "\033[38;5;196m"
yllw = "\033[38;5;220m"
reset = "\033[0m"

# tag colors
tag_colors = {"DUP": red, "DELETED": red, "INFO": yllw, "SAFE-DELETE": red}


# SIGINT handler (ctrl+c) that terminates the script with a message
def handle_sigint(signum, frame):
    error_message("interrupted process")


# receives an error message as an argument
def error_message(message):
    sys.stderr.write(f"[{red}ERROR{reset}]: {message}\n")
    sys.exit(1)


# displays a message with colored tags, separated by |
def log_files(tags, message):
    tag = "".join(f"[{tag_colors.get(t, '')}{t}{reset}]" for t in tags.split("|"))

    print(tag, message)


# deletes the files traditionally or removes them securely
def delete_file(remove, secure_rm, file):
    if remove:
        log_files("DUP|DELETED", file)
        file.unlink(missing_ok=True)
    elif secure_rm:
        log_files("DUP|SAFE-DELETE", file)
        subprocess.run(["shred", "-f", "-z", "-u", str(file)], check=True)


# create and configure the argument parser
def build_parser():
    args = argparse.ArgumentParser(description="scans the first level of a directory and checks "
                                   "if duplicate files exist.")
    args.add_argument("-v", "--version", action="version", version=VERSION, help="script version")
    args.add_argument("-r", "--remove", action="store_true", help="remove the duplicate files")
    args.add_argument("-R", '--secure-rm', action="store_true", help="safely removes using 'shred'")
    args.add_argument("-d", "--dpath", type=str, required=True, metavar="", help="directory path")

    return args


# calculates the MD5 of a file by reading in 64kb
def get_hash_md5(fpath):
    md5sum = hashlib.md5()

    with open(fpath, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b""):
            md5sum.update(chunk)

    return md5sum.hexdigest()


def main():
    # set the handler
    signal.signal(signal.SIGINT, handle_sigint)

    # parse the arguments
    args = build_parser().parse_args()

    # prevents the -r and -R parameters from being used at the same time, they are mutually exclusive
    if args.remove and args.secure_rm:
        error_message("the '-r' and '-R' parameters are mutually exclusive")

    # checks that the directory exists
    dpath = Path(args.dpath)

    log_files("INFO", "checking directory....")
    if not dpath.is_dir():
        error_message(f"the '{dpath}' directory does not exists")

    # checks that the directory contains files
    check_files = any( a.is_file() for a in dpath.iterdir() )

    log_files("INFO", "checking files....")
    if not check_files:
        error_message(f"'{dpath}' does not contain files")
    
    # iterate over all files in the directory (first level)
    total_files = 0
    duplicates_count = 0
    deleted_count = 0
    unique_hashes = set()

    log_files("INFO", f"checking duplicates in the '{dpath}' directory")
    for file in dpath.iterdir():
        if file.is_file():
            # gets the file hash
            hash_md5 = get_hash_md5(file)

            # if the hash is not in the set, it is added, if it is, it is printed to stdout
            if hash_md5 not in unique_hashes:
                unique_hashes.add(hash_md5)

            else:
                if args.remove or args.secure_rm:
                    delete_file(args.remove, args.secure_rm, file)

                    deleted_count += 1
                else:
                    log_files("DUP", file)
                
                duplicates_count += 1
            total_files += 1

    print(f"\nfiles found {total_files}, duplicates {duplicates_count}, deleted {deleted_count}")


if __name__ == "__main__":
    main()

