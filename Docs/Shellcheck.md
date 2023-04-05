### Shellcheck

I, among many, use [shellcheck](https://www.shellcheck.net/) to debug my scripts. Rather than ignoring it's usage entirely (and adding the [.shellcheckrc](/.shellcheckrc) to the `.gitignore`), I decided to add a little note here.
Since OpenWRT uses busybox, there are a few oddities compared to your regular shell. `/bin/sh` is usually a fully posix compatible shell, but in this case it is not. It uses busybox coreutils (as opposed to gnu coreutils), which are not fully posix compatible.

This means that certain shellcheck directives are actually incorrect - such is the case with [SC3045](https://www.shellcheck.net/wiki/SC3045). "In posix `sh`, `command -flag` is undefined."
Since busybox is, again, different, I have added a shellcheck directive to [.shellcheckrc](/.shellcheckrc) to disable this. If it causes issues in the future, it will be removed - please let me know if that is the case.