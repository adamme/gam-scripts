#!/bin/bash

gam="sudo $HOME/bin/gam/gam"

#find license max and user count for G Suite Enterprise Licenses
licensemax=$($gam info domain | grep 'G Suite Enterprise Licenses' | tr -cd '0-9')
usercount=$($gam info domain | grep 'G Suite Enterprise Users' | tr -cd '0-9')

#calculate and print available G Suite user licenses, then store in txt file
licensecount=$(expr $licensemax - $usercount)
echo $licensecount " G Suite User Licenses Available"

curl -X POST -H 'Content-type: application/json' --data "$(eval "echo "'{\"text\": \"$licensecount G Suite User Licenses Available\"}'"")" https://hooks.slack.com/services/######/###################
