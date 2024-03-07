#!/bin/bash
#This script performs various onboarding tasks when a user joins the company.

gam="$HOME/bin/gamadv-xtd3/gam"

#Enter new user's name
echo "User's Firstname:"
read firstname
echo "User's Lastname:"
read lastname
username=$firstname.$lastname
email=$username@domain.com

#Confirm user name before creating
read -r -p "Do you want to create $username ? [y/n] " response
if [[ $response =~ [yY] ]]
  then
      $gam create user $email firstname $firstname lastname $lastname password "temppassword" changepassword on
      $gam user $username update backupcodes
  else
  		echo "Exiting"
      exit
fi

#Move user to FTE Users (full-time employee) or TVC (temps/vendors/contractors) org
read -r -p "Is this a FTE account? [y/n] " response
if [[ $response =~ [yY] ]]
  then
      $gam update org Users add users $username
  else
  		$gam update org "Users/TVC (Temps Vendors Contractors)" add users $username
      echo "Putting user in TVC org"
      exit
fi

##Add user to appropirate basic Google groups

#office-xxx@
read -p "Which office (sfo, nyc, ber, us-remote, international-remote)? " office
$gam update group office-$office add user $username

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
