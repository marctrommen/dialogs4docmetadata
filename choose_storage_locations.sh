#!/usr/bin/env bash

source ./config
source ./config_handler.sh
export DIALOGRC=/home/marco/Scratchbook/bash/dialogs4docmetadata/dialogrc

# -------------------------------
# SETTING of variables
# -------------------------------
BACKTITEL="Dokumentarchivierung"
TITEL="Ablageort des Dokuments"
MENULIST_ITEMS=""

# -------------------------------
# FUNCTIION load_menulist ()
# load a list of items from a file and format it for use 
# in a dialog of type menu
# INPUT 
#     $1 ... input_file : fully qualified file name to load the list
# RETURN:
#     0 ... okay
#     1 ... errors
# -------------------------------
function load_menulist {

	MENULIST_ITEMS=""
	local input_file="$1"
	
	while read -r item; do
		# ignore empty lines
		if [ -z "${item}" ]; then continue; fi
		
		# ignore lines starting with '#' for coments
		if [ $( expr index "${item}" "#" ) -eq 1 ]; then continue; fi
		
		# replace any SPACE, DOT, DASH characters to UNDERSCORE
		item=$( echo -n "${item}" | tr \  \_ | tr \- \_ | tr \. \_)
		
		if [ -z "${MENULIST_ITEMS}" ]; then
			MENULIST_ITEMS="${item}"
		else
			MENULIST_ITEMS="${MENULIST_ITEMS} ${item}"
		fi
	done <"${input_file}"
	
	return 0
}


# -------------------------------
# FUNCTIION select_storage_location ()
# let the user choose a storage location of the document from a list.
# Affects the variable SCAN_DOCUMENT_STORAGE_LOCATION.
# INPUT 
#     $1 ... label: textlabel of dialog
# RETURN:
#     0 ... user okay
#     1 ... user pushed <ESC> key
# -------------------------------
function select_storage_location {
	# Generate the dialog box
	local ANSWER=$( \
		$DIALOG \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--no-cancel \
		--no-items \
		--scrollbar \
		--menu "${1}" 0 0 8 \
		${MENULIST_ITEMS} \
		3>&1 1>&2 2>&3 \
	)

	# Get the exit status
	DIALOG_EXIT_STATUS=$?

	# Handle exit status
	if [ ${DIALOG_EXIT_STATUS} -eq $BUTTON_OK ]; then
		SCAN_DOCUMENT_STORAGE_LOCATION="${ANSWER}"
		return 0
	fi
	
	SCAN_DOCUMENT_STORAGE_LOCATION=""
	return 1
}


# -------------------------------
# FUNCTIION ask_for_reselect ()
# let the user choose if he wants to redo  
# document
# INPUT 
#     $1 ... label: textlabel of dialog
# RETURN:
#     0 ..... user pushed YES
#     1 ..... user pushed NO
#     255 ... user pushed <ESC> key
# -------------------------------
function ask_for_redo {
	# Generate the dialog box
	dialog \
	--backtitle "${BACKTITEL}" \
	--title "${TITEL}" \
	--yesno "${1}" 0 0

	# Get the exit status
	return $?
}

# -------------------------------
# MAIN
# -------------------------------

ready=1

# fill MENULIST_ITEMS from file
load_menulist "${SCAN_SCRIPT_BASE_DIRECTORY}/storage_locations.txt"
return=$?

if [ $return -eq $BUTTON_OK ] ; then
	ready=1
else
	ready=0
fi


while [ $ready = 1 ] ; do
	select_storage_location "wähle aus:"
	return=$?
	
	if [ $return -eq $BUTTON_OK ] ; then
		if [ -z "${SCAN_DOCUMENT_STORAGE_LOCATION}" ] ; then
			ask_for_redo "Deine Auswahl ist leer!!\n\nAuswahl wiederholen?"
			
			return=$?
			
			# BUTTON_YES pressed?
			if [ $return -eq $BUTTON_YES ] ; then
				ready=1
			else
				ready=0
				$return=$KEY_ESC
			fi
		else
			ask_for_redo "Deine Auswahl:\n\n${SCAN_DOCUMENT_STORAGE_LOCATION}\n\nokay?"
		
			return=$?
		
			# <ESC> key pressed?
			if [ $return -eq $KEY_ESC ] ; then
				ready=0
			else
				ready=$return
			fi
		fi
	else
		ready=0
	fi

done

clear
if [ $return -eq $BUTTON_OK ] ; then
	echo "Gewählter Ablageort: ${SCAN_DOCUMENT_KEYWORDS}"
	write_config
	exit 0
fi

echo "Abbruch durch Benutzer!"
SCAN_DOCUMENT_KEYWORDS=""
write_config
exit 1
