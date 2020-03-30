#!/usr/bin/env bash
set -x
ACCOUNT_NAME=$( [[ "$( uname -s )" == "Darwin" ]] && /usr/bin/stat -f "%Su" /dev/console || { echo "- Error: Not macOS" >&2; exit 1; } )

## START: script constants
repo="macbootstrap"
tag="${repo}"
github_user="${ACCOUNT_NAME}"
file="requirements.txt"
url="https://raw.githubusercontent.com/${ACCOUNT_NAME}/${repo}/master/packages/${file}"
## END: script constants

curl -sL "${url}?$(date +%s)" > "/tmp/${file}"

if grep "${file}" "/tmp/${file}" > /dev/null 2>&1; then
  echo "+ OK: ${url} - downloaded"
else
  rm -f "/tmp/${file}"
  echo "- Error: ${url} - not downloaded" >&2; exit 1
fi

pip3 install --upgrade -q -r "/tmp/${file}"
rm -f "/tmp/${file}"
