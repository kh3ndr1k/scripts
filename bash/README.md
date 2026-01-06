# Bash scripts

## ansi-palette

display a 256 ANSI color palette in Bash ans Zsh. By default, it display the color palette in Bash, but it can
use the `bash/zsh` argument to specify which color palette to show.

#### **use**

```bash
# give execution permissions to the script
$ chmod u+x ansi-palette.sh

# execute
$ ./ansi-palette.sh

# or
$ ./ansi-palette.sh [bash/zsh]
```

## logging

A lightweight, reusable logging module for Bash scripts, with levels, priority filtering, and colored output.

#### **use**

```bash
# load the module in the script that will be used
source logging.sh

# use the logging function in the script, with the log level as the first argument and a text
# string as the second argument
logging DEBUG "Debug message"
logging INFO "Informational message"
logging WARNING "Warning message"
logging ERROR "Critical error message"
logging CRITICAL "Critical error message"
```

### vaccum-empty

A simple script that removes all empty files and directories from a directory set by default "$HOME". The script
allows adding directories to be excluded via "$IGNORED_DIRS", preventing those files and directories from
being removed.

**NOTE**: The script uses the logging.sh module, which must be located in "$HOME/.local/bash/lib/",
          if it is not found, it uses a generic logging function.

#### **use**

```bash
# give execution permissions to the script
$ chmod u+x vaccum-empty.sh

# execute
$ ./vaccum-empty.sh
```

