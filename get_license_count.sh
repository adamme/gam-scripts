#!/bin/bash

gam="sudo $HOME/bin/gam/gam"

#find license max and user count for Google Workspace Enterprise Licenses
licensemax=$($gam info domain | grep 'Google Workspace Enterprise Plus Licenses' | tr -cd '0-9')
usercount=$($gam info domain | grep 'Google Workspace Enterprise Plus Users' | tr -cd '0-9')

#calculate and print available G Suite user licenses, then store in txt file
licensecount=$(expr $licensemax - $usercount)
echo $licensecount " Google Workspace User Licenses Available"

curl -X POST -H 'Content-type: application/json' --data "$(eval "echo "'{\"text\": \"$licensecount Google Workspace User Licenses Available\"}'"")" https://hooks.slack.com/services/######/###################
