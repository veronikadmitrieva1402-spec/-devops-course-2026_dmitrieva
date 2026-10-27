#!/usr/bin/env bash

set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
fi

if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл site/index.html отсутствует. Доставка отменена." >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения. Доставка отменена." >&2
    exit 1
fi

RSYNC_CMD="rsync -avz --delete --chmod=D755,F644 -e 'ssh -o BatchMode=yes -o ConnectTimeout=5'"
echo "Синхронизация ${LOCAL_DIR} -> ${REMOTE}:${REMOTE_DIR}..."
eval "${RSYNC_CMD} ${DRY_RUN} ${LOCAL_DIR} ${REMOTE}:${REMOTE_DIR}/"

if [[ -n "${DRY_RUN}" ]]; then
    echo "Пробный запуск успешно завершен."
    exit 0
fi


if ! curl -f -s --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}"; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен после доставки." >&2
    exit 1
fi

COMMIT_HASH=$(git rev-parse --short HEAD)
echo "Успешно доставлено! Коммит: ${COMMIT_HASH}"
exit 0