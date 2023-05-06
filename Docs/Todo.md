## Todo

*This file contains a list of things that need doing. Right now, it is rudimentary; it will be updated and revitalized after the first release.*


#### Tests
- [ ] Add a test to see if wipefs is installed (`wipefs -V && echo "$?"`), and if not, use `dd if=/dev/zero of="$_DEVICE" bs=1M count=1` [link](https://superuser.com/a/1281363)

#### Misc.
- [ ] Make sure variables are named consistently