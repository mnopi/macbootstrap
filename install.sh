#!/usr/bin/env bash

ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )

## START: script constants
SECRETS_D="/Users/${ACCOUNT_NAME}/Library/Mobile Documents/com~apple~CloudDocs/secrets/secrets.d"
groups_sudoers="staff admin wheel"
enableroot="/Users/${ACCOUNT_NAME}/.enableroot"
tag="macbootstrap"
admin_user="yes"
## END: script constants

test -f "${SECRETS_D}"/*.sh && source "${SECRETS_D}"/*.sh || { echo "- Error: Not secrets files ${SECRETS_D}" >&2; exit 1; }
[[ "${ACCOUNT_PASSWD-}" ]] || { echo "- Error: ACCOUNT_PASSWD empty" >&2; exit 1; }
echo "${ACCOUNT_PASSWD}" | sudo -S true >/dev/null 2>&1 || { echo "- Error: ACCOUNT_PASSWD password - incorrect" >&2; exit 1; }

## BEGIN: script functions
tag_file() {
if ! ${2} xattr -w com.apple.metadata:_kMDItemUserTags "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\"><plist version=\"1.0\"><array><string>${tag}</string></array></plist>" "${1}"; then
  echo "= Warning: tag "${1}" - not set" >&2
fi
}
## END: script functions

# START: /etc/sudoers.d
for group_sudoers in ${groups_sudoers}; do
  if [[ ! -f "/etc/sudoers.d/${group_sudoers}" ]]; then
    echo "%${group_sudoers} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo 'Defaults !env_reset' | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo 'Defaults env_delete = "HOME"' | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo 'Defaults env_delete = "PS1"' | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    echo "Defaults: %${group_sudoers} !logfile, !syslog" | sudo tee -a "/etc/sudoers.d/${group_sudoers}" >/dev/null 2>&1
    tag_file "/etc/sudoers.d/${group_sudoers}" sudo
    echo "+ OK: /etc/sudoers.d/${group_sudoers}"
  fi
done
## END: /etc/sudoers.d

## START: enable root
test -f "${enableroot}" || { dsenableroot -u "${ACCOUNT_NAME}" -p "${ACCOUNT_PASSWD}" -r "${ACCOUNT_PASSWD}" && { touch "${enableroot}"; tag_file "${enableroot}"; echo "+ OK: root enabled"; } || echo "- Error: enable root" >&2; }
## END: enable root

## BEGIN: csrutil disable
if ! csrutil status | grep disabled > /dev/null 2>&1; then
  echo " - Disable csrutil to continue: csrutil disable"
  csrutil_change="yes"
  read -n 1 -s -r -p "Press any key to reboot: "
  echo
  sudo reboot
fi
## END: csrutil disable

## BEGIN: Master disable (Applications open internet)
if sudo spctl --status | /usr/bin/grep enabled >/dev/null 2>&1; then
  sudo spctl --master-disable
  echo "+ OK: spctl master - disable"
fi
## END: Master disable (Applications open internet)

## BEGIN: ipv6
while read -r interface; do
  networksetup -getinfo  "${interface}" | grep "IPv6: Off" > /dev/null 2>&1 || { sudo networksetup -setv6off  "${interface}"; echo "+ OK: IPv6 ${interface} - Off"; }
done < <( networksetup -listallnetworkservices | grep -v "asterisk" )
## ENF: ipv6

## BEGIN: locate database
test -f "${enableroot}" || { sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist >/dev/null 2>&1; touch "${enablelocate}"; tag_file "${enablelocate}"; echo "+ OK: locate database - loaded"; }
## ENF: locate database
