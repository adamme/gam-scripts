#!/usr/bin/env bash
# GAM7 Workspace admin menu.
# Tasks: email delegation, forwarding, file/Drive transfer, calendar
# permissions/transfer, out-of-office, and org-wide message removal.
#
# Navigation:
#   up/down or k/j   move selection
#   Enter            select
#   left / Esc / h   back one level (no-op on the main menu)
#   q                quit the script

set -uo pipefail

gam="$HOME/bin/gam7/gam"

# Set this to your own email. It's used as the "press Enter" default when
# granting document access (since that's usually you).
ME="CHANGE-ME@domain.com"

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
                printf '  \033[36m›\033[0m \033[7m %d. %s \033[0m\033[K\n' "$((i + 1))" "${options[i]}"
            else
                printf '    %d. %s\033[K\n' "$((i + 1))" "${options[i]}"
            fi
        done
        if ((TOPLEVEL)); then
            printf '\n\033[37m  (q) to quit\033[0m\033[K\n'
        else
            printf '\n\033[37m  ← to go back   (q) to quit\033[0m\033[K\n'
        fi

        IFS= read -rsn1 key
        case "$key" in
            $'\x1b')                       # escape sequence (arrow keys) or lone Esc
                key=""                     # blank first: bash 3.2 leaves it stale on timeout
                IFS= read -rsn2 -t 1 key
                case "$key" in
                    '[A' | 'OA') ((sel = (sel - 1 + n) % n)) ;;   # up
                    '[B' | 'OB') ((sel = (sel + 1) % n)) ;;       # down
                    '[C' | 'OC') break ;;                         # right = select current item
                    '[D' | 'OD') sel=-1; break ;;                 # left = back
                    '')          sel=-1; break ;;                 # lone Esc = back
                esac
                ;;
            'k') ((sel = (sel - 1 + n) % n)) ;;   # vim up
            'j') ((sel = (sel + 1) % n)) ;;       # vim down
            'h') sel=-1; break ;;                 # vim left = back
            'l') break ;;                         # vim right = select current item
            'q') sel=-2; break ;;                 # quit
            [1-9])                                # number = jump to and select that item
                if ((key >= 1 && key <= n)); then
                    sel=$((key - 1)); break
                fi
                ;;
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

# ask_default "Prompt:" "default"  -> $REPLY, using the default when Enter is pressed
ask_default() {
    printf '\033[36m? \033[0m%s ' "$1"
    IFS= read -r REPLY
    [[ -z $REPLY ]] && REPLY="$2"
}

# extract_fileid "<url-or-id>"  -> echoes the Google file ID.
# Accepts a bare ID or a full Docs/Drive URL (/d/<id>/, ?id=<id>, /folders/<id>).
# Echoes nothing if it looks like a URL but no ID could be found.
extract_fileid() {
    local in="$1" id="" re
    in="${in//[[:space:]]/}"                 # drop any stray whitespace (IDs/URLs have none)
    if [[ $in == *http* || $in == *"/"* ]]; then
        re='/d/([A-Za-z0-9_-]+)'             # docs/sheets/slides + drive/file/d/
        if [[ $in =~ $re ]]; then id="${BASH_REMATCH[1]}"
        else
            re='[?&]id=([A-Za-z0-9_-]+)'     # open?id= / uc?id=
            if [[ $in =~ $re ]]; then id="${BASH_REMATCH[1]}"
            else
                re='/folders/([A-Za-z0-9_-]+)'
                if [[ $in =~ $re ]]; then id="${BASH_REMATCH[1]}"; fi
            fi
        fi
    else
        id="$in"                             # already a bare ID
    fi
    printf '%s' "$id"
}

finish() {
    printf '\n'   # spacing, then leave the tool -- the command's output stays on screen
    exit 0
}

# pause: on an error, let the message be read, then return to the menu
pause() {
    printf '\n\033[37mPress Enter to return to the menu...\033[0m'
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
                finish
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
                        finish
                        ;;
                    1)
                        ask "Delegate email to DELETE:"; delegate="$REPLY"
                        "$gam" user "$username" delete delegate "$delegate"
                        echo "$delegate has been deleted as a delegate for $username"
                        finish
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
                finish
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
                        finish
                        ;;
                    1)
                        ask "Forwarding address to DELETE:"; forwardingusername="$REPLY"
                        "$gam" user "$username" delete forwardingaddress "$forwardingusername"
                        echo "$forwardingusername has been deleted as a forwarding address for $username"
                        finish
                        ;;
                esac
                ;;
        esac
    done
}

do_drive() {
    while true; do
        menu_select "File / Drive" \
            "Check file ownership" \
            "Add someone to a doc" \
            "Transfer file ownership" \
            "Transfer entire Drive"
        case $CHOICE in
            -2) QUIT=1; return ;;
            -1) return ;;
            0)
                ask "FileID or URL to check:"; fileID=$(extract_fileid "$REPLY")
                if [[ -z $fileID ]]; then
                    echo "Could not read a FileID from that input. Aborting."
                    pause
                    continue
                fi
                echo "Using FileID: $fileID"
                echo "Fetching the file ownership... This may take a few minutes."
                "$gam" print ownership "$fileID"
                finish
                ;;
            1)
                ask "FileID or URL of the doc:"; fileID=$(extract_fileid "$REPLY")
                if [[ -z $fileID ]]; then
                    echo "Could not read a FileID from that input. Aborting."
                    pause
                    continue
                fi
                echo "Using FileID: $fileID"

                # The ACL command must run as the doc's owner, so find the owner first.
                echo "Looking up the document owner..."
                ownerinfo=$("$gam" print ownership "$fileID" 2>&1)
                owner=$(printf '%s\n' "$ownerinfo" | grep -iE 'owner' \
                    | grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | head -n1)
                if [[ -z $owner ]]; then
                    owner=$(printf '%s\n' "$ownerinfo" \
                        | grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | head -n1)
                fi
                if [[ -z $owner ]]; then
                    echo "Could not determine the owner of $fileID. No permission was added."
                    pause
                    continue
                fi
                echo "Owner found: $owner"

                # Grantee defaults to you (press Enter).
                ask_default "Grant access to (Enter = $ME):" "$ME"; grantee="$REPLY"
                if [[ -z $grantee ]]; then
                    echo "No grantee given and no default set (edit the ME variable). Aborting."
                    pause
                    continue
                fi

                # Role defaults to Editor (first item = highlighted = Enter picks it).
                menu_select "Role to grant (Enter = Editor)" "Editor" "Commenter" "Reader"
                case $CHOICE in
                    -2) QUIT=1; return ;;
                    -1) continue ;;
                    0) role=writer ;;
                    1) role=commenter ;;
                    2) role=reader ;;
                esac

                "$gam" user "$owner" add drivefileacl "$fileID" user "$grantee" role "$role"
                echo "Granted '$role' on $fileID to $grantee (via owner $owner)"
                finish
                ;;
            2)
                ask "Current owner's email address:"; currentowner="$REPLY"
                ask "Transfer file ownership to:"; newowner="$REPLY"
                ask "FileID or URL to transfer:"; fileID=$(extract_fileid "$REPLY")
                if [[ -z $fileID ]]; then
                    echo "Could not read a FileID from that input. Aborting."
                    pause
                    continue
                fi
                echo "Using FileID: $fileID"
                "$gam" user "$currentowner" add drivefileacl "$fileID" user "$newowner" role owner
                finish
                ;;
            3)
                ask "Transfer the Drive for (user email):"; username="$REPLY"
                ask "Transfer Drive ownership to:"; transferemail="$REPLY"
                "$gam" create datatransfer "$username" drive "$transferemail" all
                finish
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
                finish
                ;;
            1)
                ask "Calendar email address to check:"; calendaremail="$REPLY"
                "$gam" calendar "$calendaremail" show acls
                finish
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
                finish
                ;;
            3)
                ask "Calendar to transfer (current owner email):"; calendaremail="$REPLY"
                ask "Transfer calendar ownership to:"; transferemail="$REPLY"
                "$gam" create datatransfer "$calendaremail" calendar "$transferemail" releaseresources
                finish
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
                finish
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
                        finish
                        ;;
                    1)
                        ask "Email address:"; username="$REPLY"
                        "$gam" user "$username" vacation off
                        echo "The Out of Office message has been disabled for $username"
                        finish
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
        pause
        return
    fi
    "$gam" all users delete messages query "rfc822msgid:$msgid" doit
    finish
}

# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------

main() {
    trap 'tput cnorm' EXIT
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
    # The loop only ends on quit (q). Successful commands exit earlier via finish()
    # without clearing, so their output persists; here we tidy the screen on quit.
    clear
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
