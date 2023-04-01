#!/bin/sh

# This script will add the default configuration to a uci section, which will be read by the service files.
# Service files are in `/etc/init.d/``

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
# This results in `/etc/config/klipper` looking like this:
#
#    config klipper 'path'
#   	option python '/path/to/python3'
#   	option klipperpy '/path/to/klipper.py'
#   	option printercfg '/path/to/printer.cfg'
#   	option klipperlog '/path/to/klipper.log'
#
# These values are used by `/etc/init.d/klipper`

# Commit changes
uci commit klipper



#################
##  Moonraker  ##
#################

# Create a new section in UCI named 'moonraker'
uci import moonraker < /dev/null

# Define the section, `moonraker.path`
uci set moonraker.path='moonraker'
# Define values in the `moonraker.path` section
uci set moonraker.path.python='/path/to/python3'
uci set moonraker.path.moonraker_py='/path/to/moonraker.py'
uci set moonraker.path.printer_data='/path/to/printer.cfg'
# This results in `/etc/config/moonraker` looking like this:
# 
#   config moonraker 'path'
#   	option python '/path/to/python3'
#   	option moonraker_py '/path/to/moonraker.py'
#   	option printer_data '/path/to/printer.cfg'
#
# These values are used by `/etc/init.d/moonraker`

# Commit changes
uci commit moonraker


########################
##  Duet Web Control  ##
########################

# Create a new section in UCI named 'dwc'
uci import dwc < /dev/null

# Define the section, `dwc.path`
uci set dwc.path='dwc'
# Define values in the `dwc.path` section
uci set dwc.path.python='/path/to/python3'
uci set dwc.path.dwc_py='/path/to/dwc.py'
# This results in `/etc/config/dwc` looking like this:
# 
#   config dwc 'path'
#   	option python '/path/to/python3'
#   	option dwc_py '/path/to/dwc.py'
#
# These values are used by `/etc/init.d/dwc`

# Commit changes
uci commit dwc