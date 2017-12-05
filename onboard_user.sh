#!/bin/bash
#This script performs various onboarding tasks when a user joins the company.

gam="$HOME/bin/gam/gam"

#Enter new user's name
echo "User's Firstname:"
read firstname
echo "User's Lastname:"
read lastname
username=$firstname.$lastname
email=$username@coreos.com

#Confirm user name before creating
read -r -p "Do you want to create $username ? [y/n] " response
if [[ $response =~ [yY] ]]
  then
      $gam create user $email firstname $firstname lastname $lastname password "coreos" changepassword on
      $gam user $username update backupcodes
  else
  		echo "Exiting"
      exit
fi

##Add user to appropirate basic Google groups

#office-xxx@
read -p "Which office (sfo, nyc, ber)? " office
$gam update group office-$office ad user $username

#women@
read -r -p "Should user be  part of women@ ? [y/n] " response
if [[ $response =~ [yY] ]]
  then
      $gam update group women add user $username
  else
  		echo "Not added to women@"
fi

#dev@
read -r -p "Should user be  part of dev@ ? [y/n] " response
if [[ $response =~ [yY] ]]
  then
      $gam update group dev add user $username
      echo "Added user to dev@"
  else
  		echo "Not added to dev@"
fi

echo "Account creation complete!"
