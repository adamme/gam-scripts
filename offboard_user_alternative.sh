#!/bin/bash
#This script performs various offboarding tasks when a user leaves the company.

gam="$HOME/bin/gamadv-xtd3/gam"

##
## Gather information
##

# Enter user to deprovision
echo "Enter email address you wish to deprovision:"
read username

# Enter manager email of user being deprovisioned
echo "Enter email address of the employee's manager:"
read manager

# Confirm user name before deprovisioning
read -r -p "Do you want to deprovision $username and delegate Email/Calendar/Drive access to $manager ? [y/n] " response
if [[ $response =~ [nN] ]]
  then
		echo "Exiting"
		exit
fi

##
## Execute
##

# Move account to Terminated OU
$gam update user $username ou "/Terminated Users/Email Delegated" 
echo $username " Moved to Terminated OU" | tee -a /tmp/$username.log

# Re-enable account
$gam update user $username suspended off
echo $username " Account enabled" | tee -a /tmp/$username.log
# Pause to allow account to fully activate
sleep 30

# Starting deprovision
echo "Processing IT list of manual offboard steps " $username

# Transfer calendar ownership to manager
$gam create datatransfer $username calendar $manager releaseresources
echo $username " Calendar transfer initiated to " $manager | tee -a /tmp/$username.log

# Removing all mobile devices connected
echo "Gathering mobile devices for $username"
IFS=$'\n'
mobile_devices=($($gam print mobile query $username | grep -v resourceId | awk -F"," '{print $1}'))
unset IFS
	for mobileid in ${mobile_devices[@]}
		do
			$gam update mobile $mobileid action account_wipe && echo "Removing $mobileid from $username"
	done 
echo $username " Removed account from mobile devices" | tee -a /tmp/$username.log

# Pause to allow account to finish mobile device removal
sleep 30

# Delegate email inbox to manager
$gam user $username delegate to $manager
echo $username " Inbox delgated to" $manager | tee -a /tmp/$username.log

# Changing user's password to random
echo "Changing "$username"'s' password to something random"
$gam update user $username password random

# Removing all App-Specific account passwords, deleting MFA Recovery Codes, deleting all OAuth tokens
echo "Checking and Removing all of "$username"'s Application Specific Passwords, 2SV Recovery Codes, and all OAuth tokens"
$gam user $username deprovision popimap signout

# Forcing change password on next sign-in and then disabling immediately.
# Speculation that this will sign user out within 5 minutes and not allow
# user to send messages without reauthentication
echo "Setting force change password on next logon and then disabling immediately to expire current session"
$gam update user $username changepassword on 
sleep 30
$gam update user $username changepassword off

echo $username " Logins cleared: password,ASP,2FA,OAuth,cache,cookies" | tee -a /tmp/$username.log

# Removing user from all Groups
$gam user $username delete groups
echo $username " Removed from all Google groups" | tee -a /tmp/$username.log

#Transfer Drive to manager
echo "Transfering Drive data to manager"
$gam create datatransfer $username drive $manager all
echo $username " Drive transfer initiated to " $manager | tee -a /tmp/$username.log

## Printing Log location and post to Slack channel
curl -X POST -H --silent --data-urlencode "payload={\"text\": \"$(cat /tmp/$username.log | sed "s/\"/'/g")\"}" https://hooks.slack.com/services/Slack-Webhook-Code-Here
echo "Log file posted to #offboarding-notifications"
echo " Offboard complete for $username"
