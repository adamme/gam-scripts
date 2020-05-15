#!/bin/bash
#This script performs various onboarding tasks when a user joins the company.

gam="$HOME/bin/gamadv-xtd3/gam"

#Gather who to transfer data from and to
echo "Transfer from: "
read source_drive_account
echo "Transfer to:"
read destination_drive_account

#Confirm usernames before creating
read -r -p "Do you want to transfer drive data from $source_drive_account to $destination_drive_account ? [y/n] " response
if [[ $response =~ [yY] ]]
  then
      $gam create datatransfer $source_drive_account gdrive $destination_drive_account
  else
  		echo "Exiting"
      exit
fi

echo "Drive transfer initiated"
