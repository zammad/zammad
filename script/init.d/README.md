# Init Script

This directory used to contain an example init.d script for Zammad installations without Systemd. This was discontinued
since Zammad now uses non-daemonizing service processes.

If using Systemd is not an option for you, consider using the provided binary packages to install even on systems that
don't have Systemd.

Pull requests with a new init script that handles foreground processes correctly would be welcome as well.
