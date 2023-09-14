This folder stores persistent application data like unprocessable emails,
and must be shared in cluster setups to be available for all nodes.

Possible subfolders (depending on system configuration and usage):
- `var/spool/unprocessable_mail` - stores emails that could not properly be imported

Just for reference, Zammad 6.1 and earlier did also store here:
- `var/spool/oversized_mail` - emails that were rejected as too big