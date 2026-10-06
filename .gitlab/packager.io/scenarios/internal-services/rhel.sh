#!/usr/bin/bash

set -eu

# systemd is not reachable yet right after container start, and reports "degraded" inside
# containers once boot has finished.
booted=false
for _ in $(seq 60); do
  case "$(systemctl is-system-running 2>/dev/null || true)" in
    running|degraded) booted=true; break ;;
  esac
  sleep 1
done

if [ "$booted" != true ]; then
  echo "systemd did not finish booting within 60 seconds." >&2
  exit 1
fi

dnf install -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

dnf reinstall -y zammad

curl --retry 30 --retry-delay 1 --retry-connrefused http://localhost:3000 | grep "Zammad Helpdesk"

# Backup script does not work on RHEL out of the box, so we cannot test it.
