#!/usr/bin/env bash

ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )

## START: script constants
repo="macbootstrap"
tag="${repo}"
github_user="${ACCOUNT_NAME}"
## END: script constants

url="https://raw.githubusercontent.com/${ACCOUNT_NAME}/${repo}/master/packages/Brewfile"
curl -sL "${url}?$(date +%s)" > /tmp/Brewfile

if grep brew /tmp/Brewfile > /dev/null 2>&1; then
  echo "+ OK: ${url} - downloaded"
else
  rm -f /tmp/Brewfile
  echo "- Error: ${url} - not downloaded" >&2; exit 1
fi

brew bundle --file /tmp/Brewfile
brew bundle cleanup --force --file /tmp/Brewfile
sudo xattr -d -r com.apple.quarantine /Applications
