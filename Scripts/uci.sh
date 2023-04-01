#!/bin/sh

# This script will add the default configuration to a uci section, which will be read by the service files.
# Service files are in `/etc/init.d/`

###############
##  Klipper  ##
###############

# Create a new subsystem in UCI named 'klipper'
uci import klipper < /dev/null

# Define the section, `klipper.path`
uci set klipper.path='klipper'
# Define values in the `klipper.path` section
uci set klipper.path.python='/path/to/python3'
uci set klipper.path.klipper_py='/path/to/klipper.py'
uci set klipper.path.printer_cfg='/path/to/printer.cfg'
uci set klipper.path.klipper_log='/path/to/klipper.log'
# Commit changes
uci commit klipper



#################
##  Moonraker  ##
#################

# Create a new subsystem in UCI named 'moonraker'
uci import moonraker < /dev/null

# Define the section, `moonraker.path`
uci set moonraker.path='moonraker'
# Define values in the `moonraker.path` section
uci set moonraker.path.python='/path/to/python3'
uci set moonraker.path.moonraker_py='/path/to/moonraker.py'
uci set moonraker.path.printer_data='/path/to/printer.cfg'
# These values are used by `/etc/init.d/moonraker`

# Commit changes
uci commit moonraker


########################
##  Duet Web Control  ##
########################

# Create a new subsystem in UCI named 'dwc'
uci import dwc < /dev/null

# Define the section, `dwc.path`
uci set dwc.path='dwc'
# Define values in the `dwc.path` section
uci set dwc.path.python='/path/to/python3'
uci set dwc.path.dwc_py='/path/to/dwc.py'
# Commit changes
uci commit dwc