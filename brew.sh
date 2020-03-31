#!/usr/bin/env bash

ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )
set -x
## START: script constants
repo="macbootstrap"
tag="${repo}"
github_user="${ACCOUNT_NAME}"
file="Brewfile"
url="https://raw.githubusercontent.com/${ACCOUNT_NAME}/${repo}/master/packages/${file}"
## END: script constants

curl -sL "${url}?$(date +%s)" > "/tmp/${file}"

if grep "${file}" "/tmp/${file}" > /dev/null 2>&1; then
  echo "+ OK: ${url} - downloaded"
else
  rm -f "/tmp/${file}"
  echo "- Error: ${url} - not downloaded" >&2; exit 1
fi

brew bundle --file "/tmp/${file}" || { echo "- Error: brew bundle --file /tmp/${file}" >&2; exit 1; }
brew bundle cleanup --force --file "/tmp/${file}"  || { echo "- Error: brew bundle cleanup --force --file /tmp/${file}" >&2; exit 1; }
sudo xattr -d com.apple.quarantine /Applications > /dev/null 2>&1
rm -f "/tmp/${file}"
rm -f "/tmp/${file}.lock.json"
