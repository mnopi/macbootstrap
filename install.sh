#!/usr/bin/env bash

ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )

## START: script constants
SECRETS_D="/Users/${ACCOUNT_NAME}/Library/Mobile Documents/com~apple~CloudDocs/secrets/secrets.d"
groups_sudoers="staff admin wheel"
admin_user="yes"
## END: script constants

test -f "${SECRETS_D}"/*.sh && source "${SECRETS_D}"/*.sh || { echo "- Error: Not secrets files ${SECRETS_D}" >&2; exit 1; }
[[ "${ACCOUNT_PASSWD-}" ]] || { echo "- Error: ACCOUNT_PASSWD empty" >&2; exit 1; }
echo "${ACCOUNT_PASSWD}" | sudo -S true >/dev/null 2>&1 || { echo "- Error: ACCOUNT_PASSWD password - incorrect" >&2; exit 1; }

## START: /etc/sudoers.d
for group_sudoers in ${groups_sudoers}; do
  if [[ ! -f "/etc/sudoers.d/${group_sudoers}" ]]; then
    echo "%${group_sudoers} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo 'Defaults !env_reset' | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo 'Defaults env_delete = "HOME"' | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo 'Defaults env_delete = "PS1"' | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo "Defaults: %${group_sudoers} !logfile, !syslog" | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
  fi
done
## END: /etc/sudoers.d

