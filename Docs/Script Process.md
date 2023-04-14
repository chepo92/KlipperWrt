### Script Process
*This document describes what happens, and in what order, during the `klipperwrt.sh` script.*

1. Check for an existing configuration
    - Attempt to read from a temporary configuration file, which is dynamically generated when the user enters values in step 2
2. Gather information
    - The script prompts the user to enter in values for all configurable options.
        - If it is a required value (and there is no default), then the script will reprompt the user until a value is given.
        - As values are given, write them to a configuration file. This configuration file can be used when calling the script to bypass the need for user interaction, or to pick up where it left off if the installer was interrupted.
        