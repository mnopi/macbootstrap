#!/usr/bin/env bash

ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )

## START: script constants
SECRETS_D="/Users/${ACCOUNT_NAME}/Library/Mobile Documents/com~apple~CloudDocs/secrets/secrets.d"
admin_user="yes"
## END: script constants

test -f "${SECRETS_D}"/*.sh && source "${SECRETS_D}"/*.sh || { echo "- Error: Not secrets files ${SECRETS_D}" >&2; exit 1; }
[[ ! "${ACCOUNT_PASSWD-}" ]] || { echo "- Error: ACCOUNT_PASSWD empty" >&2; exit 1; }
echo "${ACCOUNT_PASSWD}"
