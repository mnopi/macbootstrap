#!/usr/bin/env bash

ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )

## START: script constants
repo="macbootstrap"
tag="${repo}"
github_user="${ACCOUNT_NAME}"
## END: script constants

url="https://raw.githubusercontent.com/${ACCOUNT_NAME}/${repo}/master/packages/requirements.txt"
curl -sL "${url}?$(date +%s)" > /tmp/requirements.txt

if grep ansible /tmp/requirements.txt > /dev/null 2>&1; then
  echo "+ OK: ${url} - downloaded"
else
  rm -f /tmp/requirements.txt
  echo "- Error: ${url} - not downloaded" >&2; exit 1
fi

pip3 install --upgrade -r /tmp/requirements.txt
