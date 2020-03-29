#!/usr/bin/env bash

## START: script constants
admin_user="yes"
## END: script constants

USER_PASSWD="aaaa"
security find-generic-password -s "${USER}" -a USER_PASSWD -w

security add-generic-password -s "${USER}" -a "USER_PASSWD" -w "${USER_PASSWD}" -A -U
security add-generic-password -s "${USER}" -a "USER_PASSWD" -w "${USER_PASSWD}" -A 

USER_PASSWD

echo "${USER_PASSWD}" | sudo -S true -k
