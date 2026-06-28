#!/usr/bin/env bash
# GAMADV-XTD3 Workspace admin menu.
# Tasks: email delegation, forwarding, file/Drive transfer, calendar
# permissions/transfer, out-of-office, and org-wide message removal.
#
# Navigation:
#   up/down or k/j   move selection
#   Enter            select
#   left / Esc / h   back one level (no-op on the main menu)
#   q                quit the script

set -uo pipefail

gam="$HOME/bin/gamadv-xtd3/gam"

CHOICE=-1     # set by menu_select: index >= 0, -1 = back, -2 = quit
QUIT=0        # set to 1 by a submenu when the user chooses quit
TOPLEVEL=0    # 1 only while the main menu is drawing (suppresses the back hint)

# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

# menu_select "Title" "Option 1" "Option 2" ...
# Draws an arrow-key menu and stores the result in $CHOICE:
#   >= 0  chosen index      -1  back      -2  quit
# Returns via the global (NOT stdout) so the drawing isn't swallowed by $(...).
menu_select() {
    local title="$1"; shift
    local options=("$@")
    local n=${#options[@]}
    local sel=0 key i

    clear
    tput civis
    while true; do
        printf '\033[1m%s\033[0m\033[K\n\n' "$title"
        for ((i = 0; i < n; i++)); do
            if ((i == sel)); then
                printf '  \033[36m›\033[0m \033[7m %s \033[0m\033[K\n' "${options[i]}"
            else
                printf '    %s\033[K\n' "${options[i]}"
            fi
        done
        if ((TOPLEVEL)); then
            printf '\n\033[2m  up/down move - Enter select - q quit\033[0m\033[K\n'
        else
            printf '\n\033[2m  ← to go back   -   up/down move - Enter select - q quit\033[0m\033[K\n'
        fi

        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')                       # escape sequence (arrow keys) or lone Esc
                key=""                     # blank first: bash 3.2 leaves it stale on timeout
                IFS= read -rsn2 -t 1 key
                case "$key" in
                    '[A' | 'OA') ((sel = (sel - 1 + n) % n)) ;;   # up
                    '[B' | 'OB') ((sel = (sel + 1) % n)) ;;       # down
                    '[D' | 'OD') sel=-1; break ;;                 # left = back
                    '')          sel=-1; break ;;                 # lone Esc = back
                esac
                ;;
            'k') ((sel = (sel - 1 + n) % n)) ;;   # vim up
            'j') ((sel = (sel + 1) % n)) ;;       # vim down
            'h') sel=-1; break ;;                 # vim left = back
            'q') sel=-2; break ;;                 # quit
            '')  break ;;                         # Enter = select
        esac

        tput cuu $((n + 4))   # climb back over title(2) + options(n) + hint(2)
    done
    tput cnorm
    CHOICE=$sel
}

# ask "Prompt:"  -> reads a line of free text into $REPLY
ask() {
    printf '\033[36m? \033[0m%s ' "$1"
    IFS= read -r REPLY
}

pause() {
    printf '\n\033[2mPress Enter to continue...\033[0m'
    IFS= read -r _
}

# ---------------------------------------------------------------------------
# Task branches  (each loops so "back" returns here, one level up)
# ---------------------------------------------------------------------------

do_delegation() {
    while true; do
        menu_select "Email delegation" "Check delegates" "Add or delete a delegate"
        case $CHOICE in
            -2) QUIT=1; return ;;
            -1) return ;;
            0)
                ask "Email address to check delegates for:"; username="$REPLY"
                "$gam" user "$username" print delegates
                pause
                ;;
            1)
                ask "Mailbox email address:"; username="$REPLY"
                menu_select "Add or delete a delegate for $username" "Add" "Delete"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0)
                        ask "Delegate email to ADD:"; delegate="$REPLY"
                        "$gam" user "$username" delegate to "$delegate"
                        echo "$delegate has been added as a delegate for $username"
                        pause
                        ;;
                    1)
                        ask "Delegate email to DELETE:"; delegate="$REPLY"
                        "$gam" user "$username" delete delegate "$delegate"
                        echo "$delegate has been deleted as a delegate for $username"
                        pause
                        ;;
                esac
                ;;
        esac
    done
}

do_forwarding() {
    while true; do
        menu_select "Forwarding" "Check forwarding address" "Add or delete forwarding address"
        case $CHOICE in
            -2) QUIT=1; return ;;
            -1) return ;;
            0)
                ask "Email address to check forwarding for:"; username="$REPLY"
                "$gam" user "$username" show forward
                pause
                ;;
            1)
                ask "Mailbox to configure forwarding for:"; username="$REPLY"
                menu_select "Add or delete forwarding for $username" "Add" "Delete"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0)
                        ask "Forwarding address to ADD:"; forwardingusername="$REPLY"
                        "$gam" user "$username" add forwardingaddress "$forwardingusername"
                        "$gam" user "$username" forward on keep "$forwardingusername"
                        echo "Emails for $username are being forwarded to $forwardingusername"
                        sleep 3
                        "$gam" user "$forwardingusername" sendemail recipient "$username" subject "Email Forwarding Notification" message "Hello, \n\nThis is a notification that your email has been forwarded to $forwardingusername. Be sure to disable email forwarding when you are back in office.
            Go to https://mail.google.com/mail/u/0/#settings/fwdandpop > Select Disable forwarding.
            Alternatively, you can go to your Gmail > Settings gear icon and select See all settings > Forwarding and POP/IMAP tab > Select Disable forwarding. "
                        echo "Email notification of email forwarding has been sent to $username"
                        pause
                        ;;
                    1)
                        ask "Forwarding address to DELETE:"; forwardingusername="$REPLY"
                        "$gam" user "$username" delete forwardingaddress "$forwardingusername"
                        echo "$forwardingusername has been deleted as a forwarding address for $username"
                        pause
                        ;;
                esac
                ;;
        esac
    done
}

do_drive() {
    while true; do
        menu_select "File / Drive" "Check file ownership" "Transfer file ownership" "Transfer entire Drive"
        case $CHOICE in
            -2) QUIT=1; return ;;
            -1) return ;;
            0)
                ask "FileID to check:"; fileID="$REPLY"
                echo "Fetching the file ownership... This may take a few minutes."
                "$gam" show ownership "$fileID"
                pause
                ;;
            1)
                ask "Current owner's email address:"; currentowner="$REPLY"
                ask "Transfer file ownership to:"; newowner="$REPLY"
                ask "FileID to transfer:"; fileID="$REPLY"
                "$gam" user "$currentowner" add drivefileacl "$fileID" user "$newowner" role owner
                pause
                ;;
            2)
                ask "Transfer the Drive for (user email):"; username="$REPLY"
                ask "Transfer Drive ownership to:"; transferemail="$REPLY"
                "$gam" create datatransfer "$username" drive "$transferemail" all
                pause
                ;;
        esac
    done
}

do_calendar() {
    while true; do
        menu_select "Shared calendars / Calendar permissions" \
            "Check a user's calendar access" \
            "Check access permissions for a calendar" \
            "Add or update calendar permissions" \
            "Transfer entire calendar"
        case $CHOICE in
            -2) QUIT=1; return ;;
            -1) return ;;
            0)
                ask "Email to check calendar access for:"; username="$REPLY"
                menu_select "Is $username a user or a group?" "User" "Group"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0) usertype=user ;;
                    1) usertype=group ;;
                esac
                menu_select "Output to Google Sheets?" "Yes" "No"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0) "$gam" "$usertype" "$username" print calendars showhidden todrive ;;
                    1) "$gam" "$usertype" "$username" print calendars showhidden ;;
                esac
                pause
                ;;
            1)
                ask "Calendar email address to check:"; calendaremail="$REPLY"
                "$gam" calendar "$calendaremail" show acls
                pause
                ;;
            2)
                menu_select "Add or update calendar permissions?" "Add" "Update"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0) action=add ;;
                    1) action=update ;;
                esac

                perms=(editor owner reader writer)
                menu_select "Permission to set" "${perms[@]}"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    *) calendarpermission=${perms[$CHOICE]} ;;
                esac

                ask "Email address to grant the permission to:"; username="$REPLY"
                menu_select "Is $username a user or a group?" "User" "Group"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0) usertype=user ;;
                    1) usertype=group ;;
                esac

                ask "Calendar email address to modify:"; calendaremail="$REPLY"

                if [[ $action == add ]]; then
                    "$gam" calendar "$calendaremail" add acls "$calendarpermission" "$username" sendnotifications false
                    "$gam" "$usertype" "$username" add calendar "$calendaremail" selected true
                    echo "$username has been added $calendarpermission permissions for $calendaremail"
                else
                    "$gam" calendar "$calendaremail" update acls "$calendarpermission" "$usertype" "$username"
                    echo "$username permission for $calendaremail has been updated to: $calendarpermission"
                fi
                pause
                ;;
            3)
                ask "Calendar to transfer (current owner email):"; calendaremail="$REPLY"
                ask "Transfer calendar ownership to:"; transferemail="$REPLY"
                "$gam" create datatransfer "$calendaremail" calendar "$transferemail" releaseresources
                pause
                ;;
        esac
    done
}

do_ooo() {
    while true; do
        menu_select "Vacation / Out of Office" "Check OOO message" "Enable or disable OOO message"
        case $CHOICE in
            -2) QUIT=1; return ;;
            -1) return ;;
            0)
                ask "Email to check the OOO message for:"; username="$REPLY"
                "$gam" user "$username" show vacation format
                pause
                ;;
            1)
                menu_select "Enable or disable the OOO message?" "Enable" "Disable"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0)
                        ask "Email address:"; username="$REPLY"
                        printf 'The default out of office message is the following:\n|  Hello,\n|\n|  I am currently OOO and will respond to your message as soon as I return. Thank you!\n\n'
                        "$gam" user "$username" vacation on subject "Out of Office" message "Hello,\n\nI am currently OOO and will respond to your message as soon as I return. Thank you! " start 2000-01-01 end 2999-01-01
                        "$gam" user "$username" show vacation
                        pause
                        ;;
                    1)
                        ask "Email address:"; username="$REPLY"
                        "$gam" user "$username" vacation off
                        echo "The Out of Office message has been disabled for $username"
                        pause
                        ;;
                esac
                ;;
        esac
    done
}

do_purge() {
    ask "RFC822 Message-ID to remove from ALL mailboxes:"; msgid="$REPLY"
    # Empty-input guard (not a confirmation) -- prevents a malformed query.
    if [[ -z $msgid ]]; then
        echo "No Message-ID provided."
    else
        "$gam" all users delete messages query "rfc822msgid:$msgid" doit
    fi
    pause
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

main() {
    trap 'tput cnorm; clear' EXIT
    while true; do
        TOPLEVEL=1
        menu_select "GAM Workspace Admin - select a task" \
            "Email delegation" \
            "Forwarding" \
            "File / Drive" \
            "Shared calendars / Calendar permissions" \
            "Vacation / Out of Office" \
            "Remove an email from ALL mailboxes"
        TOPLEVEL=0
        case $CHOICE in
            0) do_delegation ;;
            1) do_forwarding ;;
            2) do_drive ;;
            3) do_calendar ;;
            4) do_ooo ;;
            5) do_purge ;;
            -2) break ;;        # q = quit
            -1) : ;;            # back on the main menu = no-op
        esac
        ((QUIT)) && break
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
