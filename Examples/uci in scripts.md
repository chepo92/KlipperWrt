# Parsing `uci` configuration in shell scripts
---

> The abbreviation UCI stands for Unified Configuration Interface, and is a system to centralize the configuration of OpenWrt services.

KlipperWRT-EX has been built with this in mind, and has been made compatible with UCI using its in-built tools.
The primary way this is acheived is by using `config_load` and `config_get` - functions provided by `/lib/functions.sh`. `functions.sh` is simply a shell script that contains several shell functions which can be called at any time.

Before you can use the functions, you need to include `/lib/functions.sh`. There are several ways to do this:
- A shell script with the `#!/bin/sh /etc/rc.common` shebang will include `/lib/functions.sh` by default
- Adding the line `. /lib/functions.sh` on the line below the shebang:
```bash
#!/bin/sh
. /lib/functions.sh
```
- `source`ing the script with `source /lib/functions.sh`

In all cases, make sure the line that includes `functions.sh` occurs *before* you attempt to execute any of its functions, or the command will be undefined. Ex:
```bash
#!/bin/sh
. /lib/functions.sh
config_load myconfig
config_get var section option
```
is correct, but
```bash
#!/bin/sh
config_load myconfig
config_get var section option
. /lib/functions.sh
```
returns
```
./test.sh: line 2: config_load: not found
./test.sh: line 3: config_get: not found
```


## Using `config_load` and `config_get`
---
After including `/lib/functions.sh`, you can use these as you would any other command. Type the name of the command (`config_load`) and add any other arguments you want to pass on to it.
`config_load` takes one argument - the name of the uci subsystem that you want to load. This is synonymous with the name of a file in `/etc/config` - running `config_load network` will load all the values from `/etc/config/network`.
`config_load` is similar to the above `source` command - you must run `config_load` *before* running `config_get`, or it won't function properly.

`config_get` takes three arguments; `var`, `section`, and `option`. These are synonymous with the [elements in the UCI data object model](https://openwrt.org/docs/guide-user/base-system/uci#elements):
![image.png](https://openwrt.org/_media/media/doc/howtos/uci_hr_named.png)
Let's say I want a script that will get the value from the sixth line, `ipaddr`, and print it to the user. The script would look something like this:
```bash
#!/bin/sh
# Source the `functions.sh` script
. /lib/functions.sh
# Load the network configuration file
config_load network
# Get the value from the named section, `lan`, the option, `ipaddr`, and load it into the variable, `var`
config_get var lan ipaddr
# `echo` the variable `var`
echo "$var"
```