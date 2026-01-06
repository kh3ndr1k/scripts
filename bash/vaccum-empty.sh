#!/usr/bin/bash
set -u

# load the logging.sh file if it exists, otherwise, load a generic function
# log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
if [[ -f "$HOME/.local/lib/bash/logging.sh" ]]; then
	source "$HOME/.local/lib/bash/logging.sh"

	# reset the log level to the default
	LOG_LEVEL="INFO"
else
	logging() { local level="${1^^}"; shift; printf '[%s] %s\n' "$level" "$*"; }
fi

# set the base directory where it will start searching for empty files and directories
BASE_DIR="$HOME"

# ignore directories that are added to the list
IGNORED_DIRS=()

# generate an expression that the find command canuse to exclude files
gen_expr() {
	if (( ${#IGNORED_DIRS[@]} > 0 )); then
		local expression
		expression=$(printf ' -name %q -o' "${IGNORED_DIRS[@]}")
		expression=${expression% -o}

		echo "$expression"
	else
		echo ""
	fi
}


# get the expression that the find command will use to exclude files, otherwise, it only
# receives an empty strings
PRUNE_EXPR=$(gen_expr)

# if $PRUNE_EXPR is an empty string, process all directories starting from $BASE_DIR,
# otherwise, exclude the directories in the list
if [[ -n "$PRUNE_EXPR" ]]; then
	empty_files_deleted=$(find "$BASE_DIR" \( $PRUNE_EXPR \) -prune -o -type f -empty -print -exec rm -f {} \; | wc -l)
	empty_dirs_deleted=$(find "$BASE_DIR" \( $PRUNE_EXPR \) -prune -o -type d -empty -print | wc -l)

	# attempt to remove any remaining empty directories
	while true; do
		find $BASE_DIR \( $PRUNE_EXPR \) -prune -o -type d -empty -exec rmdir -p {} \; 2>/dev/null

		[[ $? -eq 0 ]] && break
	done
else
	empty_files_deleted=$(find "$BASE_DIR" -type f -empty -print -delete | wc -l)
	empty_dirs_deleted=$(find "$BASE_DIR" -depth -type d -empty -print -delete | wc -l)
fi

# display the corresponding message indicating whether file or directories were deleted or no
if [[ $empty_files_deleted -eq 0 && $empty_dirs_deleted -eq 0 ]]; then
	logging INFO "No empty files or directories found"
else
	logging INFO "${empty_files_deleted} empty files and ${empty_dirs_deleted} empty directories deleted"
fi

