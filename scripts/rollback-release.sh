#!/usr/bin/env bash

set -Eeuo pipefail

APP_ROOT="/var/www/zywlu"

if [[ "${EUID}" -ne 0 ]]; then
  echo "rollback-release.sh must run as root" >&2
  exit 2
fi

if [[ ! -L "${APP_ROOT}/current" || ! -L "${APP_ROOT}/previous" ]]; then
  echo "Current or previous release link is missing" >&2
  exit 2
fi

current_target="$(readlink -f "${APP_ROOT}/current")"
previous_target="$(readlink -f "${APP_ROOT}/previous")"

if [[ "${previous_target}" != "${APP_ROOT}/releases/"* || ! -f "${previous_target}/index.html" ]]; then
  echo "Previous release is invalid" >&2
  exit 3
fi

nginx -t

ln -sfn -- "${previous_target}" "${APP_ROOT}/current.next"
mv -Tf -- "${APP_ROOT}/current.next" "${APP_ROOT}/current"
ln -sfn -- "${current_target}" "${APP_ROOT}/previous"

if ! systemctl reload nginx; then
  ln -sfn -- "${current_target}" "${APP_ROOT}/current"
  ln -sfn -- "${previous_target}" "${APP_ROOT}/previous"
  echo "Nginx reload failed; release links restored" >&2
  exit 4
fi

echo "Rolled back to ${previous_target}"
