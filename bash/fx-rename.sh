#!/bin/bash

# color list
RED="\e[38;5;196m"
YLL="\e[38;5;227m"
RST="\e[00m"

# script version
VERSION='8.0.0'

# characterse to be used from the MD5 hash
HASH_LEN=10

# use the default hash to rename
USE_HASH=true

# does not use dry-run by default
DRY_RUN=false

# does not use the default prefix
DEFAULT_PREFIX=false


# send a message when CTRL+C is pressed
ctrl_c_handler(){
    error_message "process canceled"
}
trap ctrl_c_handler SIGINT

# takes a text as an argument, displays it on stderr and terminates the script
error_message(){
    local msg="$1"
    echo -e "\n${RED}[ERROR]${RST}: $msg\n" >&2
    exit 1
}

# script help menu
help_menu(){
cat << EOF
Use: ${0##*/} -d <directory> [-v] [-h] [-D] [-l 1-32:md5] [-p] [-i "prefix"] [-n]

Description:
Renames the media files in a directory. By default, it renames them using the file hash (10 chars by default).
You can also skip using the hash with '-n', but this only works when a prefix is required. Using '-i' allows
you to provide a custom prefix, while '-p' adds the default prefix (IMG for images, VID for vides, Etc.).
Before applying the changes you can use '-D' to display the results without modifying anything.

Options:
-d          Directory with files to renamed.
-l          Hash length (default ${HASH_LEN}).
-n          Does not use the default hash to rename, this option requires using -p / -i.
-D          Dry-run: shows the changes without renaming files.
-i          Receives a prefix as input.
-p          Use the default prefixes, identifying the file type.
-h          Help menu.
-v          Script version.
EOF
exit 0
}

# check that the directory exists and contains files
validate_directory(){
    local dir_path="$1"

    if [[ -z "$dir_path" ]]; then
        error_message "the directory path is not specifified, use -d <directory>."
    fi

    if [[ ! -d "$dir_path" ]]; then
        error_message "'$dir_path' directory does not exit"
    fi

    if ! find "$dir_path" -maxdepth 1 -type f | read; then
        error_message "no files were found in the '$dir_path' directory"
    fi
}

# split the file into file path, file name and extension
split_file(){
    local filepath="$1"
    local dirpath="${filepath%/*}"      # file path
    local filename="${filepath##*/}"    # file name
    local extension="${filename##*.}"   # extension

    echo "$dirpath" "$filename" "${extension,,}"
}

# gets the file type based on the file extension
get_filetype(){
    local extension="$1"

    case "$extension" in
        jpg|jpeg|png|gif|webp) echo "IMG" ;;
        mp4|mkv|mov|avi|webm)  echo "VID" ;;
        mp3|wav|opus|flac|ogg) echo "AUD" ;;
        *) echo "UNK" ;;
    esac
}

# process the files in the directory
process_files(){
    local dry_run="$1"
    local dir_path="$2"
    local hash_len="$3"
    local use_prefix="$4"

    if "$USE_HASH"; then
        # preocess the files using only the hash
        process_name(){
            local dry_run="$1"
            local file_path="$2"
            local hash_len="$3"

            # get the file path, file name and extension
            read -r dir_path filename extension < <(split_file "$file_path")
            # get the md5 hash of the file
            read -r hash _ < <(md5sum "$file_path")

            # set the new file name and path
            hash="${hash^^}"
            new_filename="${dir_path}/${hash:0:$hash_len}.$extension"

            # check if the dry-run will be used
            if [[ "$dry_run" == true ]]; then
                echo -e "${YLL}dry-run${RST} '$file_path' -> '$new_filename'"
                return 0
            fi

            # Check that the same file name does not already exist
            if [[ ! -f "$new_filename" ]]; then
                mv -v "$file_path" "$new_filename"
            fi
        }
    else
        # process the files without using the hash, but using a prefix
        process_name(){
            local dry_run="$1"
            local file_path="$2"
            local use_prefix="$4"

            # get the file path, file name and extension
            read -r dir_path filename extension < <(split_file "$file_path")

            # check if the default prefix will be used or not
            if [[ "$use_prefix" == default ]]; then
                prefix=$(get_filetype "$extension")
            else
                prefix="$use_prefix"
            fi
          
            # set the new file name and path
            new_filename="${dir_path}/${prefix}-${filename%.*}.${extension}"

            # check if the dry-run will be used
            if [[ "$dry_run" == true ]]; then
                echo -e "${YLL}dry-run${RST} '$file_path' -> '$new_filename'"
                return 0
            else
                mv -v "$file_path" "$new_filename"
            fi
        }
    fi

    find "$dir_path" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do
        process_name "$dry_run" "$file" "$hash_len" "$use_prefix"
    done
}


# verify that at least one parameter is passed
if [[ $# -eq 0 ]]; then
    help_menu
fi

# iterate over the command line options
while getopts ":d:l:i:pDnvh" args 2>/dev/null; do
    case "$args" in
        \?)
            error_message "Invalid option: '-$OPTARG'" ;;
        :)
            error_message "'-$OPTARG' requires an argument" ;;
        h)
            help_menu ;;
        v)
            echo -e "v$VERSION"; exit 0 ;;
        d)
            dir_path="$OPTARG" ;;
        l)
            HASH_LEN="$OPTARG" ;;
        n)
            USE_HASH=false ;;
        D)
            DRY_RUN=true ;;
        i)
            input_prefix="$OPTARG" ;;
        p)
            DEFAULT_PREFIX=true ;;
    esac
done

if [[ "$USE_HASH" == "false" ]]; then
      # the -i and -o parameteres are mutyally exclusive
      if [[ "$DEFAULT_PREFIX" == true && -n "$input_prefix" ]]; then
          error_message "the use of '-i' and '-p' is mutually exclusive"
      fi

      # check whether the default prefix or the input prefix will be used; if not, it shows an error
      if [[ "$DEFAULT_PREFIX" == true ]]; then
          use_prefix="default"
      elif [[ -n "$input_prefix" ]]; then
          use_prefix="$input_prefix"
      else
        error_message "the '-n' parameter requires the '-i/-p' parameter"  
      fi
fi

# validate the integrity of the directory
validate_directory "$dir_path"

process_files "$DRY_RUN" "$dir_path" "$HASH_LEN" "$use_prefix"

