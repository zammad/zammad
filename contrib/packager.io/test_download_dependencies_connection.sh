#!/bin/sh

check_urls() {
  requirement="$1"
  shift
  for url in "$@"; do
    printf "  %-30s%-15s" "$url" "($requirement)"
    if curl -4 -m5 -fsS "$url" -o /dev/null; then
      echo "✔ OK"
    else
      echo "✖ FAIL"
    fi
  done
}

echo
echo "For Zammad installation/updates:"
check_urls required \
  https://artifacts.elastic.co \
  https://dl.packager.io \
  https://go.packager.io
check_urls optional \
  https://geo.zammad.com \
  https://google.com
echo

echo "For Zammad package (addon) installation/updates:"
check_urls required \
  https://index.rubygems.org \
  https://registry.npmjs.org
echo
