#!/bin/sh

# This is purgatory, where code snippets go to die
# Code snippets here are under current development, and may be introduced in later versions.

### Argument parsing

## $PROG $VER
## Designed for busybox sh
## 
## Usage: $PROG [OPTION...] [COMMAND]...
## Options:
##   -c, --config	        Use a preexisting config
##   -q, --log-quiet        Set log level to quiet
##   -l, --log MESSAGE      Log a message
## Commands:
##   -h, --help             Displays this help and exists
##   -v, --version          Displays output version and exists
## Examples:
##   $PROG -i myscrip-simple.sh > myscript-full.sh
##   $PROG -r myscrip-full.sh   > myscript-simple.sh

# /^##\s\+\(-[a-zA-Z]\|--[a-zA-Z-]\+\)\s\+\(.*\b\Q-h\E\b.*\)$/s//\1/p
# ^## *-h, --\K[^= ]*|^##.* --\K${1#--}(?:[= ])
# shellcheck disable=SC2034
PROG='KlipperWRT-EX'
# shellcheck disable=SC2034
VER='1.0 - [2023-03-05]'

# -arg section
help(){
	grep "^##" "$0" | sed -e "s/^...//" -e "s/\$PROG/$PROG/g"; exit 0
}
version() {
  help | head -1
}
# -arg functions, provided by @tet on stackoverflow: https://stackoverflow.com/a/47339704
# While the number of arguments passed is greater than 0; do
while [ $# -gt 0 ]; do
	# Set $CMD to a grep command which looks for the current argument
	CMD=$(grep -m 1 -o "^## *$1, --\K[^= ]*|^##.* --\K${1#--}(?:[= ])" "$0" | sed -e "s/-/_/g")
	# If the output of $CMD is null (could not find argument); return command not supported
	if [ -z "$CMD" ]; then echo "ERROR: Command '$1' not supported"; exit 1; fi
	# Move arguments by one place (dropping the first arg); then execute the output of $CMD in a subshell;
	# Pass all arguments the script was invoked with (this is affected by shift) to the subshell, for handling
	# things such as -c /path/to/config
	shift; $CMD "$@" || shift $? 2> /dev/null
done



while [ -z "$DEVPATH" ]; do
	true
done
echo 'Choose your device from the list below: '
array=$(block info | grep -vE '/dev/ubi.*|/dev/mtd.*' | sed -rn 's/^/Device: /p')
read -rp 'Enter the full path to your device: ' DEVPATH

# Testing config_foreach from /lib/functions.sh
#!/bin/sh

. /lib/functions.sh

config_load klipper

bind_mount(){
        echo "Arg 1 is '$1'"
        echo "Your custom arg is '$2'"
        config_get VAR "$1" target
        echo "The value you asked for is '$VAR'"
        echo "Finished loop one

        "
}

config_foreach bind_mount mount test


# Testing if config_load works within subshells
#!/bin/sh

. /lib/functions.sh

flibblewop(){
        config_load klipper
}
config_get VAR path python
echo "$VAR"



# Aliases to add to /etc/shinit or $HOME/.shinit
mkscript() { vi "$1" && chmod +x "$1"; }

# Lazy search regex
grep -E '.*?'

# Redirect all output to stderr
# POSIX compliant
echo 'Error' 1>&2

# Silence all output
# POSIX compliant

#!/bin/sh
echo 'A tree wonders; if it falls with nobody around, did it even make a sound? 
It screams, for it does not know.' > /dev/null 2>&1 