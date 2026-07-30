#!/usr/bin/env bash

set -Eeuo pipefail

: "${RELEASE_ID:?RELEASE_ID is required}"
: "${ARCHIVE:?ARCHIVE is required}"
: "${NGINX_TEMPLATE:?NGINX_TEMPLATE is required}"

DOMAIN="${DOMAIN:-_}"
KEEP_RELEASES="${KEEP_RELEASES:-3}"
APP_ROOT="/var/www/zywlu"
RELEASES_DIR="${APP_ROOT}/releases"
RELEASE_DIR="${RELEASES_DIR}/${RELEASE_ID}"
STAGING_DIR="${RELEASE_DIR}.staging"
NGINX_SITE="/etc/nginx/sites-available/zywlu"

if [[ ! "${RELEASE_ID}" =~ ^[0-9A-Za-z._-]+$ ]]; then
  echo "Invalid RELEASE_ID" >&2
  exit 2
fi

if [[ ! "${DOMAIN}" =~ ^[_0-9A-Za-z.-]+$ ]]; then
  echo "Invalid DOMAIN" >&2
  exit 2
fi

if [[ ! "${KEEP_RELEASES}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid KEEP_RELEASES" >&2
  exit 2
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "activate-release.sh must run as root" >&2
  exit 2
fi

if [[ ! -f "${ARCHIVE}" || ! -f "${NGINX_TEMPLATE}" ]]; then
  echo "Release archive or Nginx template is missing" >&2
  exit 2
fi

if ! command -v nginx >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
fi

install -d -m 0755 "${APP_ROOT}" "${RELEASES_DIR}"

if [[ ! -d "${RELEASE_DIR}" ]]; then
  rm -rf -- "${STAGING_DIR}"
  install -d -m 0755 "${STAGING_DIR}"
  tar -xzf "${ARCHIVE}" -C "${STAGING_DIR}"

  if [[ ! -f "${STAGING_DIR}/index.html" || ! -f "${STAGING_DIR}/404.html" ]]; then
    echo "Release does not contain index.html and 404.html" >&2
    exit 3
  fi

  find "${STAGING_DIR}" -type d -exec chmod 0755 {} +
  find "${STAGING_DIR}" -type f -exec chmod 0644 {} +
  mv -- "${STAGING_DIR}" "${RELEASE_DIR}"
fi

previous_target=""
had_current=0
if [[ -L "${APP_ROOT}/current" ]]; then
  had_current=1
  previous_target="$(readlink -f "${APP_ROOT}/current")"
  ln -sfn -- "${previous_target}" "${APP_ROOT}/previous"
fi

ln -sfn -- "${RELEASE_DIR}" "${APP_ROOT}/current.next"
mv -Tf -- "${APP_ROOT}/current.next" "${APP_ROOT}/current"

nginx_candidate="$(mktemp)"
nginx_backup="$(mktemp)"
had_nginx_site=0
had_default_site=0

if [[ -f "${NGINX_SITE}" ]]; then
  had_nginx_site=1
  cp -- "${NGINX_SITE}" "${nginx_backup}"
fi

if [[ -L /etc/nginx/sites-enabled/default ]]; then
  had_default_site=1
fi

restore_previous_state() {
  set +e

  if [[ "${had_current}" -eq 1 ]]; then
    ln -sfn -- "${previous_target}" "${APP_ROOT}/current"
  else
    rm -f -- "${APP_ROOT}/current"
  fi

  if [[ "${had_nginx_site}" -eq 1 ]]; then
    install -m 0644 "${nginx_backup}" "${NGINX_SITE}"
    ln -sfn -- "${NGINX_SITE}" /etc/nginx/sites-enabled/zywlu
  else
    rm -f -- "${NGINX_SITE}" /etc/nginx/sites-enabled/zywlu
  fi

  if [[ "${had_default_site}" -eq 1 ]]; then
    ln -sfn -- /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
  fi

  if nginx -t >/dev/null 2>&1 && systemctl is-active --quiet nginx; then
    systemctl reload nginx
  fi

  set -e
}

sed "s/__SERVER_NAME__/${DOMAIN}/g" "${NGINX_TEMPLATE}" >"${nginx_candidate}"
install -m 0644 "${nginx_candidate}" "${NGINX_SITE}"
rm -f -- "${nginx_candidate}"
ln -sfn -- "${NGINX_SITE}" /etc/nginx/sites-enabled/zywlu
rm -f -- /etc/nginx/sites-enabled/default

if ! nginx -t; then
  restore_previous_state
  rm -f -- "${nginx_backup}"
  echo "Nginx configuration test failed" >&2
  exit 4
fi

if ! systemctl enable --now nginx || ! systemctl reload nginx; then
  restore_previous_state
  rm -f -- "${nginx_backup}"
  echo "Nginx start or reload failed" >&2
  exit 5
fi

rm -f -- "${nginx_backup}"
current_target="$(readlink -f "${APP_ROOT}/current")"

mapfile -t stale_releases < <(
  find "${RELEASES_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' |
    sort -rn |
    tail -n "+$((KEEP_RELEASES + 1))" |
    cut -d' ' -f2-
)

for stale_release in "${stale_releases[@]}"; do
  if [[ "${stale_release}" == "${RELEASES_DIR}/"* && "${stale_release}" != "${current_target}" && "${stale_release}" != "${previous_target}" ]]; then
    rm -rf -- "${stale_release}"
  fi
done

echo "Activated ${RELEASE_ID} at ${RELEASE_DIR}"
