#!/usr/bin/env bash

set -Eeuo pipefail

: "${PRIMARY_DOMAIN:?PRIMARY_DOMAIN is required}"
: "${EMAIL:?EMAIL is required}"
: "${HTTPS_TEMPLATE:?HTTPS_TEMPLATE is required}"

SERVER_NAMES="${SERVER_NAMES:-${PRIMARY_DOMAIN}}"
CERTIFICATE_DOMAINS="${CERTIFICATE_DOMAINS:-${PRIMARY_DOMAIN}}"
CERT_NAME="${CERT_NAME:-${PRIMARY_DOMAIN}}"
DRY_RUN_RENEWAL="${DRY_RUN_RENEWAL:-true}"
HTTPS_SITE="/etc/nginx/sites-available/zywlu-https"
HTTPS_LINK="/etc/nginx/sites-enabled/zywlu-https"
REDIRECT_FILE="/etc/nginx/zywlu-http-enabled/redirect.conf"
WEBROOT="/var/lib/letsencrypt"

domain_pattern='^[_0-9A-Za-z.-]+([[:space:]]+[_0-9A-Za-z.-]+)*$'

if [[ ! "${PRIMARY_DOMAIN}" =~ ^[0-9A-Za-z.-]+$ ]]; then
  echo "Invalid PRIMARY_DOMAIN" >&2
  exit 2
fi

if [[ ! "${SERVER_NAMES}" =~ ${domain_pattern} || ! "${CERTIFICATE_DOMAINS}" =~ ${domain_pattern} ]]; then
  echo "Invalid SERVER_NAMES or CERTIFICATE_DOMAINS" >&2
  exit 2
fi

if [[ ! "${CERT_NAME}" =~ ^[0-9A-Za-z.-]+$ || ! "${EMAIL}" =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
  echo "Invalid CERT_NAME or EMAIL" >&2
  exit 2
fi

if [[ "${DRY_RUN_RENEWAL}" != "true" && "${DRY_RUN_RENEWAL}" != "false" ]]; then
  echo "Invalid DRY_RUN_RENEWAL" >&2
  exit 2
fi

if [[ "${EUID}" -ne 0 ]]; then
  echo "enable-https.sh must run as root" >&2
  exit 2
fi

if [[ ! -f "${HTTPS_TEMPLATE}" ]]; then
  echo "HTTPS template is missing" >&2
  exit 2
fi

if ! command -v certbot >/dev/null 2>&1; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y certbot
fi

install -d -m 0755 \
  "${WEBROOT}/.well-known/acme-challenge" \
  /etc/nginx/zywlu-http-enabled \
  /etc/letsencrypt/renewal-hooks/deploy

nginx -t
systemctl reload nginx

domain_arguments=()
for domain in ${CERTIFICATE_DOMAINS}; do
  domain_arguments+=(--domain "${domain}")
done

certbot certonly \
  --webroot \
  --webroot-path "${WEBROOT}" \
  --cert-name "${CERT_NAME}" \
  "${domain_arguments[@]}" \
  --expand \
  --email "${EMAIL}" \
  --agree-tos \
  --non-interactive \
  --keep-until-expiring

if [[ ! -f "/etc/letsencrypt/live/${CERT_NAME}/fullchain.pem" || ! -f "/etc/letsencrypt/live/${CERT_NAME}/privkey.pem" ]]; then
  echo "Certificate files are missing" >&2
  exit 3
fi

https_candidate="$(mktemp)"
redirect_candidate="$(mktemp)"
https_backup="$(mktemp)"
redirect_backup="$(mktemp)"
had_https_site=0
had_redirect=0

if [[ -f "${HTTPS_SITE}" ]]; then
  had_https_site=1
  cp -- "${HTTPS_SITE}" "${https_backup}"
fi

if [[ -f "${REDIRECT_FILE}" ]]; then
  had_redirect=1
  cp -- "${REDIRECT_FILE}" "${redirect_backup}"
fi

restore_previous_state() {
  set +e

  if [[ "${had_https_site}" -eq 1 ]]; then
    install -m 0644 "${https_backup}" "${HTTPS_SITE}"
    ln -sfn -- "${HTTPS_SITE}" "${HTTPS_LINK}"
  else
    rm -f -- "${HTTPS_SITE}" "${HTTPS_LINK}"
  fi

  if [[ "${had_redirect}" -eq 1 ]]; then
    install -m 0644 "${redirect_backup}" "${REDIRECT_FILE}"
  else
    rm -f -- "${REDIRECT_FILE}"
  fi

  if nginx -t >/dev/null 2>&1; then
    systemctl reload nginx
  fi

  set -e
}

sed \
  -e "s/__PRIMARY_DOMAIN__/${PRIMARY_DOMAIN}/g" \
  -e "s/__SERVER_NAME__/${SERVER_NAMES}/g" \
  -e "s/__CERT_NAME__/${CERT_NAME}/g" \
  "${HTTPS_TEMPLATE}" >"${https_candidate}"
printf 'return 308 https://%s$request_uri;\n' "${PRIMARY_DOMAIN}" >"${redirect_candidate}"

install -m 0644 "${https_candidate}" "${HTTPS_SITE}"
install -m 0644 "${redirect_candidate}" "${REDIRECT_FILE}"
ln -sfn -- "${HTTPS_SITE}" "${HTTPS_LINK}"

if ! nginx -t; then
  restore_previous_state
  echo "HTTPS Nginx configuration test failed" >&2
  exit 4
fi

if ! systemctl reload nginx; then
  restore_previous_state
  echo "HTTPS Nginx reload failed" >&2
  exit 5
fi

cat >/etc/letsencrypt/renewal-hooks/deploy/zywlu-nginx <<'HOOK'
#!/bin/sh
set -eu
nginx -t
systemctl reload nginx
HOOK
chmod 0755 /etc/letsencrypt/renewal-hooks/deploy/zywlu-nginx

systemctl enable --now certbot.timer

if [[ "${DRY_RUN_RENEWAL}" == "true" ]]; then
  certbot renew \
    --cert-name "${CERT_NAME}" \
    --dry-run \
    --non-interactive \
    --no-random-sleep-on-renew
fi

rm -f -- "${https_candidate}" "${redirect_candidate}" "${https_backup}" "${redirect_backup}"
echo "HTTPS enabled for ${CERTIFICATE_DOMAINS}"
