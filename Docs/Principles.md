###  Core Principles

KlipperWRT-EX revolves around a few core principles:
- UCI integration
    - OpenWRT, the underlying linux distrobution, uses a system called UCI - **U**nified **C**onfiguration **I**nterface. As the name implies, configuration for pretty much everything is stored here - no more digging around in `/etc/` for the right `.conf` file. This allows settings to be changed declaratively throughout the system, and easy integration with other programs such as LuCI.
    - With KlipperWRT-EX, I've built it such that (almost) everything is configured in UCI. This would theoretically allow someone to create a `luci-app-klipperwrt` package that would allow simple configuration from LuCI - OpenWRTs WebUI
- Reproducibility
    - The thing that bothers me with a lot of self hosted things is that due to minute changes between system configuration, the whole thing can go bork. While I can't cover every single edge case, I try to develop KlipperWRT-EX such that it is simple to reproduce, and edge cases are at a minimum. And if it isn't covered, the documentation (which at this point is still a WIP) should be able to help you troubleshoot much better than the original KlipperWRT.
- Simplicity
    - As they say, Keep It Stupid Simple. I try to take the solution that is streamlined and integrated into the underlying system (OpenWRT), so that edge cases are, again, kept to a minimum.
- Safety
    - KlipperWRT-EX takes a different approach to installation when it comes to storage. Rather than using the traditional extroot method, KlipperWRT-EX uses bind mounted BTRFS subvolumes. This comes with the benefit of being less intrusive than extroot, as well as laying the ground work for snapshots.
    - In an embedded system like this, updates don't tend to happen frequently. In fact, OpenWRT recommends you don't run `opkg upgrade`, going so far as requiring the user to specify which packages to upgrade by name, each time. So when an upgrade *does* happen, it is crucial that you can simply roll back your system if anything goes haywire. Especially if you run KlipperWRT-EX on your edge router like me.