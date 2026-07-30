#!/usr/bin/env bash

set -Eeuo pipefail

: "${DEPLOY_HOST:?DEPLOY_HOST is required}"

DEPLOY_USER="${DEPLOY_USER:-root}"
DEPLOY_PORT="${DEPLOY_PORT:-22}"
DEPLOY_DOMAIN="${DEPLOY_DOMAIN:-_}"
KEEP_RELEASES="${KEEP_RELEASES:-3}"
RELEASE_ID="${RELEASE_ID:-$(git rev-parse --short=12 HEAD)}"
REMOTE_STAGE="/tmp/zywlu-${RELEASE_ID}"
SSH_TARGET="${DEPLOY_USER}@${DEPLOY_HOST}"
ARCHIVE="$(mktemp "${TMPDIR:-/tmp}/zywlu-release.XXXXXX.tar.gz")"

if [[ ! "${DEPLOY_HOST}" =~ ^[0-9A-Za-z.:-]+$ ]]; then
  echo "Invalid DEPLOY_HOST" >&2
  exit 2
fi

if [[ ! "${DEPLOY_USER}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "Invalid DEPLOY_USER" >&2
  exit 2
fi

if [[ ! "${DEPLOY_PORT}" =~ ^[0-9]+$ || ! "${RELEASE_ID}" =~ ^[0-9A-Za-z._-]+$ ]]; then
  echo "Invalid DEPLOY_PORT or RELEASE_ID" >&2
  exit 2
fi

if [[ ! "${DEPLOY_DOMAIN}" =~ ^[_0-9A-Za-z.-]+$ || ! "${KEEP_RELEASES}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid DEPLOY_DOMAIN or KEEP_RELEASES" >&2
  exit 2
fi

cleanup() {
  rm -f -- "${ARCHIVE}"
}
trap cleanup EXIT

command -v npm >/dev/null
command -v ssh >/dev/null
command -v scp >/dev/null
command -v tar >/dev/null
command -v curl >/dev/null

npm ci
npm run check
tar -C dist -czf "${ARCHIVE}" .

ssh -p "${DEPLOY_PORT}" "${SSH_TARGET}" "mkdir -p '${REMOTE_STAGE}'"
scp -P "${DEPLOY_PORT}" \
  "${ARCHIVE}" \
  infra/nginx/zywlu.conf \
  scripts/activate-release.sh \
  "${SSH_TARGET}:${REMOTE_STAGE}/"

if [[ "${DEPLOY_USER}" == "root" ]]; then
  REMOTE_PRIVILEGE="env"
else
  REMOTE_PRIVILEGE="sudo env"
fi

ssh -p "${DEPLOY_PORT}" "${SSH_TARGET}" \
  "${REMOTE_PRIVILEGE} RELEASE_ID='${RELEASE_ID}' DOMAIN='${DEPLOY_DOMAIN}' KEEP_RELEASES='${KEEP_RELEASES}' ARCHIVE='${REMOTE_STAGE}/$(basename "${ARCHIVE}")' NGINX_TEMPLATE='${REMOTE_STAGE}/zywlu.conf' bash '${REMOTE_STAGE}/activate-release.sh'"

HEALTH_URL="${HEALTH_URL:-http://${DEPLOY_HOST}/}"
curl --fail --silent --show-error --max-time 15 "${HEALTH_URL}" >/dev/null
echo "Deployment healthy: ${HEALTH_URL} (${RELEASE_ID})"
