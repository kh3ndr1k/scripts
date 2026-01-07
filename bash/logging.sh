# Global log level (minimum level to display)
LOG_LEVEL=INFO   # values: DEBUG, INFO, WARNING, ERROR, CRITICAL

# ANSI 256-color codes for log levels
GRAY=$'\033[38;5;240m'
RED=$'\033[38;5;196m'
BLUE=$'\033[38;5;027m'
YELLOW=$'\033[38;5;214m'
RESET=$'\033[0m'

# Map of log levels to numeric priority (lower = more verbose)
declare -A LOG_LEVEL_PRIORITIES=([DEBUG]=0 [INFO]=1 [WARNING]=2 [ERROR]=3 [CRITICAL]=4)

# Map of log levels to colors
declare -A LOG_LEVEL_COLORS=([DEBUG]="$GRAY" [INFO]="$BLUE" [WARNING]="$YELLOW" [ERROR]="$RED" [CRITICAL]="$RED")


# Logging function
logging() {
    local level="${1^^}"   # Convert first argument to uppercase
    shift                  # Remove first argument, leaving message in $*

    # Build the colored label for the level
    local label="${LOG_LEVEL_COLORS[$level]}[$level]$RESET"

    # Skip messages below the configured log level
    [[ ${LOG_LEVEL_PRIORITIES[$level]} -lt ${LOG_LEVEL_PRIORITIES[$LOG_LEVEL]} ]] && return

    # Print CRITICAL or ERROR messages to stderr, others to stdout
    if [[ $level == 'ERROR' || $level == 'CRITICAL' ]]; then
        printf '%s %s\n' "$label" "$*" >&2
    else
        printf '%s %s\n' "$label" "$*"
    fi
}

# -------------------------------------------------
# Example usage:
#
# load the loggins.sh file inside a bash script
#
# source logging.sh
#
# use:
#
# logging DEBUG "Debug message"
# logging INFO "Informational message"
# logging WARNING "Warning message"
# logging ERROR "ERROR message"
# logging CRITICAL "Critical error message"

