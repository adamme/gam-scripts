#!/bin/bash
#This script performs various tasks.
#The commands involve email delegation, forwarding email, file or drive ownership/transfer, calendar permissions or transfer, and out of office messages.

gam="$HOME/bin/gamadv-xtd3/gam"

##
## Gather information
##

# Enter menu option
echo "Please type a number to run the following (example: 1)
    >1. Email delegation 
    >2. Forwarding Email
    >3. File / Drive
    >4. Shared calendars / Calendar permissions
    >5. Vacation / Out of Office message"
    read menuselection

# Executing email delegation menu
if [[ $menuselection =~ [1] ]]
	then 
	
	# Enter email delegate menu option
	echo "Please type a number to run the following (example: 1)
	>1. Check email delegates
	>2. Add or delete email delegate "
	read delegatemenuselection 

	# Executing check email delegates
	if [[ $delegatemenuselection =~ [1] ]]
		then 
		
		# Enter user to delegate
		echo "Enter the email address you wish to check the delegates for : "
		read username
		
		# Confirm user and delegate
		read -r -p "Do you wish to check the delegates for $username ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
		
		# Check email delegation
		$gam user $username print delegates
		
		fi # End $delegatemenuselection 1 IF statement
	
	# Executing add or delete email delegates
	if [[ $delegatemenuselection =~ [2] ]]
		then 
		
		read -r -p "Do you wish to add or delete an email delegate? [add/delete] " adddelete 
		if [[ $adddelete != [aA][dD][dD] ]] && [[ $adddelete != [dD][eE][lL][eE][tT][eE] ]] 
			then
				echo "Incorrect option. Exiting..."
				return
			fi # End IF
	
		# Enter user to delegate
		echo "Enter the user email address to delegate: "
		read username
		
		# Enter user you are delegating to
		echo "Enter the email address you wish to $adddelete as a delegate : "
		read delegate
		
		# Confirm user and delegate
		read -r -p "Do you wish to $adddelete $delegate as a delegate for $username ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
		
		# Executing Case for add or delete email delegate
		case $adddelete in
		
		# add delegate
		[aA][dD][dD])
			$gam user $username delegate to $delegate
			echo "$delegate has been added as a delegate for $username "
			;;
		
		# delete delegate
		[dD][eE][lL][eE][tT][eE]) 
			$gam user $username delete delegate $delegate
			echo "$delegate has been deleted as a delegate for $username "
			;;
			
		# incorrect option; exit
		*) 
			echo "Incorrect option. Exiting..."
			return
			;;
			
		esac # End $adddelete Case Statement
		
	    fi # End $delegatemenuselection 2 IF statement
	
	fi # End $menuselection IF 1 statement

# Executing forwarding menu selection
if [[ $menuselection =~ [2] ]]
	then 
	
	# Enter forwarding menu option
	echo "Please type a number to run the following (example: 1)
	>1. Check forwarding address
	>2. Add or Delete forwarding address"
	read forwardmenuselection
	
	# Executing show forwarding address
	if [[ $forwardmenuselection =~ [1] ]]
		then 
		
		# Enter user to check forwarding for
		echo "Enter the email address you wish to check the email forwarding for : "
		read username
		
		# Confirm user to check forwarding for
		read -r -p "Do you wish to check the forwarding address for $username ? [y/n] " response
		
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
			
		# Show forwarding address
		$gam user $username show forward
		
		fi # End $forwardmenuselection 1 IF statement
	
	# Executing add and set forwarding address
		
	if [[ $forwardmenuselection =~ [2] ]]
		then 
	
		# Enter user to forward Email
		echo "Enter the email address to forward: "
		read username

        read -r -p "Do you wish to add or delete a forwarding address? [add/delete] " adddelete 
		if [[ $adddelete != [aA][dD][dD] ]] && [[ $adddelete != [dD][eE][lL][eE][tT][eE] ]] 
			then
				echo "Incorrect option. Exiting..."
				return
			fi # End IF
		
		# Enter user to add/delete as forwarding address
		echo "Enter the email address you wish to $adddelete as a forwarding address : "
		read forwardingusername
		
		# Confirm user and add/delete forwarding address
		read -r -p "Do you wish to $adddelete $forwardingusername as a forwarding address for $username ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
		
		# Executing Case for add or delete forwarding address
		case $adddelete in
		
		# add forwarding address
		[aA][dD][dD])
			# Adding forwarding address
			$gam user $username add forwardingaddress $forwardingusername
		
			# Enabling / set email forwarding 
			$gam user $username forward on keep $forwardingusername
			echo "Emails for $username are being forwarded to $forwardingusername"
			
			sleep 3
			
			# Send email notification of forwarding to user
			$gam user $forwardingusername sendemail recipient $username subject "Email Forwarding Notification" message "Hello, \n\nThis is a notification that your email has been forwarded to $forwardingusername. Be sure to disable email forwarding when you are back in office. 
            Go to https://mail.google.com/mail/u/0/#settings/fwdandpop > Select Disable forwarding.
            Alternatively, you can go to your Gmail > Settings gear icon and select See all settings > Forwarding and POP/IMAP tab > Select Disable forwarding. "
			echo "Email notification of email forwarding has been sent to $username "
			;;
		
		# delete forwarding address
		[dD][eE][lL][eE][tT][eE]) 
			$gam user $username delete forwardingaddress $forwardingusername
			echo $forwardingusername " has been deleted as a forwarding address for " $username
			;;
			
		#incorrect option; exit
		*) 
			echo "Incorrect option. Exiting..."
			return
			;;
			
		esac # End $adddelete Case Statement
		
		fi # End $forwardmenuselection 2 IF statement
	
    fi # End $menuselection 2 IF statement

# Executing File / Drive menu
if [[ $menuselection =~ [3] ]]
	then
	
	# Enter file menu option
	echo "Please type a number to run the following (example: 1)
	>1. Check file ownership
	>2. Transfer file ownership
	>3. Transfer entire Drive"
	read filemenuselection
	
	# Executing check file ownership 
	if [[ $filemenuselection =~ [1] ]]
		then 
		
		echo "Enter the FileID you would like to check: "
		read fileID
		
		# Confirm file ownership check
		read -r -p "Do you wish to check the ownership of fileID: $fileID ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
		
        echo fetching the file ownership... This may take a few minutes.

		# Check fileID ownership
		$gam show ownership $fileID
		
		fi # End $filemenuselection 1 IF statement
		
	# Executing transfer file ownership 
	if [[ $filemenuselection =~ [2] ]]
		then 
		
		echo "Enter the current Owner's email address : "
		read currentowner
		
		echo "Enter the email address you want to transfer file ownership to: "
		read newowner
		
		echo "Enter the FileID you would like to transfer: "
		read fileID
		
		# Confirm file ownership check
		read -r -p "
		Current Owner: $currentowner
		New Owner: $newowner
		FileID: $fileID 
		
		Do you wish to transfer the ownership of the file? [y/n] " response
		
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF

		# Transfer file ownership
		$gam user $currentowner add drivefileacl $fileID user $newowner role owner
		
		fi # End $filemenuselection 2 IF statement

	# Executing Drive transfer 
	if [[ $filemenuselection =~ [3] ]]
		then 
		
		# Enter user email
		echo "Enter the email address you would like to transfer the Drive for: "
		read username
		
		#Enter transfer email
		echo "Enter the email address you would like to transfer Drive ownership to: "
		read transferemail
		
		# Confirm Transfer Drive ownership
		read -r -p "Do you wish to transfer $username 's Google Drive ownership to $transferemail ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
			
		# Transfer Google Drive ownership
		$gam create datatransfer $username drive $transferemail all
		
		fi # End $filemenuselection 3 IF statement

	fi # End $menuselection 3 IF statement

# Executing check shared calendars / add or update calendar permissions
if [[ $menuselection =~ [4] ]] 
    then

	# Enter calendar menu option
	echo "Please type a number to run the following (example: 1)
	>1. Check user's calendar access
	>2. Check access permissions for a calendar
	>3. Add or update calendar permissions
	>4. Transfer entire Calendar"
	read calendarmenuselection
    
    	# Executing Check user's calendar access
	if [[ $calendarmenuselection =~ [1] ]]
		then 
		
		# Enter email address to check calendars for
		echo "Enter the email address you wish to check calendar access for: "
		read username

        read -r -p "Is $username a user or group? [user/group] ] " usertype 
			if [[ $usertype != [uU][sS][eE][rR] ]] && [[ $usertype != [gG][rR][oO][uU][pP] ]] 
				then
					echo "Incorrect option. Exiting..."
					return
				fi # End IF
				
		read -r -p "Do you want this information in Google Sheets ? [y/n] " todriveresponse

        read -r -p "Do you wish to check the calendars for $username ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
		
        case $todriveresponse in
		
		# Yes - to drive option
		[yY])
			# Check calendar access for specific user and upload spreadsheet to Google Drive
		    $gam $usertype $username print calendars showhidden todrive
			;;
		
        # No - print to GAM option
        [nN])
		    # Check calendar access for specific user
		    $gam $usertype $username print calendars showhidden
            ;;

        # Incorrect option; exit
		*) 
			echo "Incorrect option. Exiting..."
			return
			;;
		esac # End $addupdate Case Statement            
		
		fi # End $calendarmenuselection IF 1 statement
		
	# Executing Check access permissions for a calendar
	if [[ $calendarmenuselection =~ [2] ]]
		then 
		
		# Enter Calendar email to check
		echo "Enter the Calendar email address you would like to check: "
		read calendaremail
		
		# Confirm check permissions for Calendar
		read -r -p "Do you wish to check the access permissions for $calendaremail ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
			
		# Check access permissions for a calendar
		$gam calendar $calendaremail show acls
		
		fi # End $calendarmenuselection IF 2 statement

	# Executing Add / Update calendar permissions
	if [[ $calendarmenuselection =~ [3] ]] 
		then 
		
		# Enter to add or update calendar permission
		read -r -p "Do you wish to add or update calendar permissions? [add/update] " addupdate 
			if [[ $addupdate != [aA][dD][dD] ]] && [[ $addupdate != [uU][pP][dD][aA][tT][eE] ]] 
				then
					echo "Incorrect option. Exiting..."
					return
				fi # End IF
		
		# Enter type of calendar permission to set
		read -r -p "What calendar permission should be set? [editor|owner|reader|writer] " calendarpermission 
			if [[ $calendarpermission != [eE][dD][iI][tT][oO][rR] ]] && [[ $calendarpermission != [oO][wW][nN][eE][rR] ]] && [[ $calendarpermission != [rR][eE][aA][dD][eE][rR] ]] && [[ $calendarpermission != [wW][rR][iI][tT][eE][rR] ]]
				then
					echo "Incorrect option. Exiting..."
					return
				fi # End IF
		
		# Enter email address 
		echo "Enter the email address you wish to $addupdate Calendar permissions for: "
		read username
		
		# Enter if this is a user or group
		read -r -p "Is $username a user or group? [user/group] ] " usertype 
			if [[ $usertype != [uU][sS][eE][rR] ]] && [[ $usertype != [gG][rR][oO][uU][pP] ]] 
				then
					echo "Incorrect option. Exiting..."
					return
				fi # End IF
		
		# Enter the Calendar email address to add/update
		echo "Enter the Calendar email address to $addupdate: "
		read calendaremail
	
		# Confirm Calendar and permission access
		read -r -p "Do you wish to $addupdate $calendarpermission permissions for $username to the calendar: $calendaremail ? [y/n] " response
			if [[ $response =~ [nN] ]]
				then
					echo "User selected No. Exiting..."
					return
				fi # End IF
			
		# Executing Case for add or update calendar permissions
		case $addupdate in
		
		# Add calendar permission
		[aA][dD][dD])
			$gam calendar $calendaremail add acls $calendarpermission $username sendnotifications false
			$gam $usertype $username add calendar $calendaremail selected true
			echo "$username has been added $calendarpermission permissions for $calendaremail "
			;;
		
		# Update calendar permission
		[uU][pP][dD][aA][tT][eE]) 
			$gam calendar $calendaremail update acls $calendarpermission $usertype $username
			echo "$username permission for @calendaremail has been updated to: $calendarpermission "
			;;
			
		# Incorrect option; exit
		*) 
			echo "Incorrect option. Exiting..."
			return
			;;
		esac # End $addupdate Case Statement
		
		fi # End $calendarmenuselection IF 3 statment
		
	# Executing Transfer calendar 
	if [[ $calendarmenuselection =~ [4] ]]
		then 
		
		# Enter user email
		echo "Enter the email address you would like to transfer the Calendar for: "
		read calendaremail
		
		#Enter transfer email
		echo "Enter the email address you would like to transfer Calendar ownership to: "
		read transferemail
		
		# Confirm Transfer calendar ownership
		read -r -p "Do you wish to transfer $calendaremail 's calendar ownership to $transferemail ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
			
		# Check access permissions for a calendar
		$gam create datatransfer $username calendar $transferemail releaseresources
		
		fi # End $calendarmenuselection IF 4 statement
    
    fi # End $menuselection IF 4 statement

# Executing set out of office message	
if [[ $menuselection =~ [5] ]]
    then

	# Enter out of office menu option
	echo "Please type a number to run the following (example: 1)
	>1. Check user's vacation / out of office message
	>2. Enable or Disable out of office message"
	read ooomenuselection
	
	# Executing Check user's out of office message
	if [[ $ooomenuselection =~ [1] ]]
		then 
		
		# Enter email address to check out of office message
		echo "Enter the email address you wish to check the out of office message for : "
		read username
		
		# Confirm out of office email address check
		read -r -p "Do you wish to check the out of office message for $username ? [y/n] " response
		if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
			
		# Check out of office message
		$gam user $username show vacation format
		
		fi # End $ooomenuselection IF 1 statement
		
	# Executing Enable or Disable out of office message
	if [[ $ooomenuselection =~ [2] ]]
		then 
		
		# Enter to enable or disable out of office message
		read -r -p "Do you wish to enable or disable the out of office message? [enable/disable] " enabledisable 
			if [[ $enabledisable != [eE][nN][aA][bB][lL][eE] ]] && [[ $enabledisable != [dD][iI][sS][aA][bB][lL][eE] ]] 
				then
					echo "Incorrect option. Exiting..."
					return
				fi # End IF
		
		# Enter email address for out of office message
		echo "Enter the email address you wish $enabledisable the out of office message for : "
		read username
			
		# Executing Case for enable or disable out of office message
		case $enabledisable in
		
		# Enable out of office
		[eE][nN][aA][bB][lL][eE])
		
			# Display default out of office message
			printf "The default out of office message is the following: \n|  Hello,\n|  \n|  I am currently OOO and will respond to your message as soon as I return. Thank you!\n"
			
			sleep 3
			
			# Confirm out of office message should be set
			read -r -p "Do you wish to enable and set this out of office message for $username ? [y/n] " response
			
			if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
			
			# Enable and set out of office message
			$gam user $username vacation on subject "Out of Office" message "Hello,\n\nI am currently OOO and will respond to your message as soon as I return. Thank you! " start 2000-01-01 end 2999-01-01
			
			# Displays out of office message
			$gam user $username show vacation
			;;
		
		# Disable out of office
		[dD][iI][sS][aA][bB][lL][eE]) 
			
			# Confirm out of office message should be disabled
			read -r -p "Do you wish to disable the out of office message for $username ? [y/n] " response
			
			if [[ $response =~ [nN] ]]
			then
				echo "User selected No. Exiting..."
				return
			fi # End IF
			
			# Disable out of office message
			$gam user $username vacation off
			
			sleep 3
			
			echo "$The Out of Office message has been disabled for $username "
			;;
			
		# Incorrect option; exit
		*) 
			echo "Incorrect option. Exiting..."
			return
			;;
			
		esac # End $enabledisable Case Statement
		
		fi # End $ooomenuselection IF 2 statment
		
	fi # End $menuselection IF 5 statement

 # End Script
