#!/usr/bin/env bash

ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )

## START: script constants
SECRETS_D="/Users/${ACCOUNT_NAME}/Library/Mobile Documents/com~apple~CloudDocs/secrets/secrets.d"
SSH="/Users/${ACCOUNT_NAME}/Library/Mobile Documents/com~apple~CloudDocs/secrets/ssh"
groups_sudoers="staff admin wheel"
enableroot="/Users/${ACCOUNT_NAME}/.enableroot"
enablelocate="/Users/${ACCOUNT_NAME}/.enablelocate"
repo="macbootstrap"
tag="${repo}"
github_user="${ACCOUNT_NAME}"
admin_user="yes"
admin_id="502"
scripts="brew pip npm gem"
apple_scripts="/Users/${ACCOUNT_NAME}/Library/Mobile Documents/com~apple~ScriptEditor2/Documents"
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
test -f "${enablelocate}" || { sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist >/dev/null 2>&1; touch "${enablelocate}"; tag_file "${enablelocate}"; echo "+ OK: locate database - loaded"; }
## ENF: locate database

## BEGIN: log dir
log_dir="/var/log/${ACCOUNT_NAME}"
[[ -d "${log_dir}" ]] || { sudo mkdir -p "${log_dir}"; sudo chown -R "${ACCOUNT_NAME}":$( id -g "${ACCOUNT_NAME}" ) "${log_dir}"; sudo /bin/chmod -R g+s "${log_dir}"; tag_file "${log_dir}"; echo "+ OK: ${log_dir} - created"; }
## END: log dir

## START: .hushlogin
test -f "/Users/${ACCOUNT_NAME}/.hushlogin" || { touch "/Users/${ACCOUNT_NAME}/.hushlogin"; tag_file "/Users/${ACCOUNT_NAME}/.hushlogin"; echo "+ OK: /Users/${ACCOUNT_NAME}/.hushlogin - created"; }
sudo test -f /var/root/.hushlogin || { sudo touch /var/root/.hushlogin; tag_file /var/root/.hushlogin sudo; echo "+ OK: /var/root/.hushlogin - created"; }
## END: .hushlogin

## BEGIN: .ssh
if [[ ! -d "/Users/${ACCOUNT_NAME}/.ssh" ]]; then
  mkdir "/Users/${ACCOUNT_NAME}/.ssh"; chmod go-rx "/Users/${ACCOUNT_NAME}/.ssh"
  tag_file "/Users/${ACCOUNT_NAME}/.ssh"; echo "+ OK: /Users/${ACCOUNT_NAME}/.ssh - created"
fi

if ! sudo test -d /var/root/.ssh; then
  sudo mkdir "/var/root/.ssh"; sudo chmod go-rx "/var/root/.ssh"
  tag_file "/var/root/.ssh" sudo; echo "+ OK: /var/root/.ssh - created"
fi

test -f "${SSH}/${ACCOUNT_NAME}/id_rsa" || { echo "- Error: ${SSH}/${ACCOUNT_NAME}/id_rsa - not found" >&2; exit 1; }

if ! test -f "${SSH}/${ACCOUNT_NAME}/authorized_keys"; then
  curl -s "https://github.com/${github_user}.keys" > "${SSH}/${ACCOUNT_NAME}/authorized_keys"
  if grep ssh-rsa "${SSH}/${ACCOUNT_NAME}/authorized_keys" > /dev/null 2>&1; then
    tag_file "${SSH}/${ACCOUNT_NAME}/authorized_keys"
    echo "+ OK: ${SSH}/${ACCOUNT_NAME}/authorized_keys - downloaded"
  else
    rm -f "${SSH}/${ACCOUNT_NAME}/authorized_keys"
    echo "- Error: ${SSH}/${ACCOUNT_NAME}/authorized_keys - not downloaded" >&2; exit 1
  fi
fi

if [[ ! -f "/Users/${ACCOUNT_NAME}/.ssh/id_rsa" ]]; then
  cp "${SSH}/${ACCOUNT_NAME}/id_rsa" "/Users/${ACCOUNT_NAME}/.ssh/id_rsa" && chmod go-rwx "/Users/${ACCOUNT_NAME}/.ssh/id_rsa"
  tag_file "/Users/${ACCOUNT_NAME}/.ssh/id_rsa"; echo "+ OK: /Users/${ACCOUNT_NAME}/.ssh/id_rsa - installed"
fi

if ! sudo test -f /var/root/.ssh/id_rsa; then
  sudo cp "${SSH}/${ACCOUNT_NAME}/id_rsa" "/var/root/.ssh/id_rsa" && sudo chmod go-rwx /var/root/.ssh/id_rsa
  tag_file "/var/root/.ssh/id_rsa" sudo; echo "+ OK: /var/root/.ssh/id_rsa - installed"
fi

if [[ ! -f "/Users/${ACCOUNT_NAME}/.ssh/authorized_keys" ]]; then
  cp "${SSH}/${ACCOUNT_NAME}/authorized_keys" "/Users/${ACCOUNT_NAME}/.ssh/authorized_keys" && chmod go-rwx "/Users/${ACCOUNT_NAME}/.ssh/authorized_keys"
  tag_file "/Users/${ACCOUNT_NAME}/.ssh/authorized_keys"; echo "+ OK: /Users/${ACCOUNT_NAME}/.ssh/authorized_keys - installed"
fi

if ! sudo test -f /var/root/.ssh/authorized_keys; then
  sudo cp "${SSH}/${ACCOUNT_NAME}/authorized_keys" "/var/root/.ssh/authorized_keys" && sudo chmod go-rwx /var/root/.ssh/authorized_keys
  tag_file "/var/root/.ssh/authorized_keys" sudo; echo "+ OK: /var/root/.ssh/authorized_keys - installed"
fi
## END: .ssh

## BEGIN: admin user
if [[ "${admin_user}" == "yes" ]] && ! sudo dscl . -read /Users/admin > /dev/null 2>&1; then
  if ! id "${admin_id}" > /dev/null 2>&1; then
    sudo dscl . -create /Users/admin
    sudo dscl . -create /Users/admin UserShell /bin/bash
    sudo dscl . -create /Users/admin RealName Admin
    sudo dscl . -create /Users/admin UniqueID "${admin_id}"
    sudo dscl . -create /Users/admin PrimaryGroupID $( id -g ${ACCOUNT_NAME} )
    sudo dscl . -create /Users/admin NFSHomeDirectory /Users/admin
    sudo dscl . -passwd /Users/admin "${ACCOUNT_PASSWD}"
    sudo dscl . -append /Groups/admin GroupMembership admin
    echo "+ OK: User admin - created"
  else
    echo "- Error: admin_id ${admin_id} - used" >&2; exit 1;
  fi
fi
## END: admin user

## BEGIN: iCloud
if test -d "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/"; then
  for dir in "${HOME}/iCloud" "${HOME}/Desktop/iCloud"; do
    test -d "${dir}" && test -L "${dir}" || { ln -s "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/" "${dir}"; tag_file "${dir}"; echo "+ OK: ${dir} link - created"; }
  done
else
  echo "- Error: ${HOME}/Library/Mobile Documents/com~apple~CloudDocs - not found" >&2; exit 1;
fi
## END: iCloud

## BEGIN: Remote Login
if [[ "$( sudo systemsetup -getremotelogin | awk '{print $3}' )" == "Off" ]]; then
  killall "System Preferences"
  test -f "${apple_scripts}/remote-login-click.scpt" || { echo "- Error: '${apple_scripts}/remote-login-click.scpt' not found" >&2; exit 1; }
  osascript "${apple_scripts}/remote-login-click.scpt" > /dev/null 2>&1
  sudo sqlite3 '/Library/Application Support/com.apple.TCC/TCC.db' "update access set allowed=1"
  if [[ "$( sudo systemsetup -getremotelogin | awk '{print $3}' )" == "Off" ]]; then
    osascript "${apple_scripts}/remote-login-click.scpt" || exit 1
  fi
  if [[ "$( sudo systemsetup -getremotelogin | awk '{print $3}' )" == "Off" ]]; then
    echo "- Error: Remote Login - Off" >&2; exit 1;
  else
    echo "+ OK: Remote Login - On"
  fi
fi
## END: Remote Login

## BEGIN: Printer
if ! lpstat -p HP 2>/dev/null | grep enable >/dev/null 2>&1; then
  # /etc/cups/ppd/HP.ppd
  test -d "${HOME}/Library/Printers" || mkdir -p "${HOME}/Library/Printers"

  url="https://raw.githubusercontent.com/${ACCOUNT_NAME}/${repo}/master/files/HP.ppd"
  curl -sL "${url}?$(date +%s)" > "${HOME}/Library/Printers/HP.ppd"

  if grep PPD-Adobe "${HOME}/Library/Printers/HP.ppd" > /dev/null 2>&1; then
    echo "+ OK: ${url} - downloaded"
  else
    rm -f "${HOME}/Library/Printers/HP.ppd"
    echo "- Error: ${url} - not downloaded" >&2; exit 1
  fi

  lpadmin -p HP -v "dnssd://HP._ipps._tcp.local." -P "${HOME}/Library/Printers/HP.ppd" -o printer-is-shared=false >/dev/null 2>&1
  cupsenable HP -E >/dev/null 2>&1
  cupsaccept HP >/dev/null 2>&1

  if lpstat -p HP | grep enable >/dev/null 2>&1; then
    echo "+ OK: Printer - installed"
  else
    echo "- Error: Printer - install" >&2; exit 1;
  fi
fi
## END: Printer

## BEGIN: install brew
if [[ ! -f /usr/local/bin/brew ]]; then
  yes yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi
## END: install brew

## BEGIN: scripts
for script in ${scripts}; do
  url="https://raw.githubusercontent.com/${ACCOUNT_NAME}/${repo}/master/${script}.sh"
  bash -c "$( curl -sL "${url}?$(date +%s)" )" || { echo "- Error: ${url}" >&2; exit 1; }
done
## END: scripts

## BEGIN: pip
test -f /usr/local/bin/pip && test -L /usr/local/bin/pip || { ln -s /usr/local/bin/pip3 /usr/local/bin/pip; tag_file /usr/local/bin/pip; echo "+ OK: /usr/local/bin/pip link - created"; }
## END: pip

## BEGIN: User Shell
USER_SHELL="/usr/local/bin/bash"
OLD_SHELL="$( dscl . -read /Users/"${ACCOUNT_NAME}" UserShell | awk '{print $2}' )"

if test -e "${USER_SHELL}" && [[ "${OLD_SHELL}" != "${USER_SHELL}" ]]; then
  /usr/bin/sudo /usr/bin/dscl . -change "/Users/${ACCOUNT_NAME}" UserShell "${OLD_SHELL}" "${USER_SHELL}" && echo "+ OK: User Shell - updated" || exit 1
fi
## END: User Shell

## BEGIN: paths
# con el path del repo
## END: bash

# apps
# keychain
# packages atom
# duti
# Defaults
# /usr/local/sbin en path dice brew
# Dock
# mackup
# Fonts
# Dictionaries
# Control panel
# gitconfig
