#!/usr/bin/bash

# This script facilitates the secure deletion of a complete directory, it uses the shred command
# to overwrite all files in the specified directory.
# Keep in mind that when execution the script, the files will be unrecoverable.

# version script
VERSION="6.0.0"

# list colors
RED="\e[38;5;13m"
YLL="\e[38;5;221m"
END="\e[0m"

# execution indicators
WR="${YLL}[!]${END}"

# number of overwrites 0-7
OVERWRITES=0

# disables the ^C character
stty -ctlecho

# display error messages received as function arguments
error_Messages(){
  local messages="$1"
 
  echo -e "\n${RED}[ERORR]${END}: $messages\n"
  stty ctlecho
  exit 1
}

# displays an error messages when CTRL+C is used
ctrl_c_action(){ 
  error_Messages "interrupted script"
  stty -ctlecho
}
trap ctrl_c_action SIGINT

# script help menu
help_menu(){
cat << EOF
use:
 ${0##*/} -d <path directory> [-o number overwrite] -v -h

description:
: This script facilitates the secure deletion of a complete directory, it uses the shred command
: to overwrite all files in the specified directory.
: Keep in mind that when execution the script, the files will be unrecoverable.

options:
-d        securely deletes all files in the specified directory.
-o        specifies the number of times each file will be overwritten. (default 0)
-v        display the script version.
-h        display the script help menu.
EOF
exit 0
}

secure_erase_dir(){
  local dpath="$1"
  local overwrites=$2
  local count=1

  # get the total number of files in the directory
  local total_files=$(find "$dpath" -type f 2>/dev/null | wc -l)

  if [[ $total_files -eq 0 ]]; then
      echo -e "$total_files files found, nothing to do"
      exit 0
  fi

  # get the directory size
  local dir_size=$(du -sh "$dpath" 2>/dev/null | cut -f1)

  # display a summary of the total number of files and the directory size
  echo -e "${WR} $dir_size of disk space will be freed"
  echo -e "${WR} $total_files files will be securely overwritten"

  # display a confirmation message
  echo -en "${WR} ${RED}are you sure you want to continue? this action is irreversible ${END}[y/n]: "; read answer

  if [[ "${answer,,}" != 'y' ]]; then
      echo -e "\n${YLL}!${END} terminated ${YLL}¡${END}\n"
      exit 1
  fi
  
  # process all files in the directory, overwrite them, and show a summary of the process
  sleep 1
  while IFS= read -r -d '' file; do
      echo -e "[$count/$total_files] $file"

      shred -f -z -u -n $overwrites "$file" 2>/dev/null
      ((count++))
  done < <(find "$dpath" -type f -print0)
  stty -ctlecho
}


if [[ $# -eq 0 ]]; then
  help_menu
fi

# parses the command line parameters
while getopts ':d:o:vh' args 2>/dev/null; do
    case "$args" in
        \?)
            error_Messages "-$OPTARG is not a valid parameter, use -h."
            ;;
        :)
            error_Messages "-$OPTARG requires an argument, use -h."
            ;;
        h)
            help_menu
            ;;
        v)
            echo -e "$VERSION"; exit 0
            ;;
        o)
            OVERWRITES=$OPTARG
            ;;
        d)
            DPATH="$OPTARG"
            ;;
    esac
done

# checks that the directory exists
if [[ ! -d "$DPATH" ]]; then
  error_Messages "Directory '$DPATH' does not exist."
fi

secure_erase_dir "$DPATH" "$OVERWRITES"

