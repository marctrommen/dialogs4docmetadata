#!/usr/bin/env bash

source ./config
source ./config_handler.sh

# -------------------------------
# SETTING of variables
# -------------------------------
BACKTITEL="Dokumentarchivierung"
TITEL="Textmuster in Metadaten suchen"
SEARCH_PATTERN=""

# -------------------------------
# FUNCTIION get_search_pattern ()
# let the user enter text for search pattern.
# affects the variable SEARCH_PATTERN
# INPUT
#     $1 ... label: textlabel of dialog
# RETURN:
#     0 ... okay
#     1 ... user pushed <ESC> key
# -------------------------------
function get_search_pattern {

	ANSWER=""
	while [ "${ANSWER}" = "" ] ; do
		# Generate the dialog box
		ANSWER=$( \
			$DIALOG \
			--backtitle "${BACKTITEL}" \
			--title "${TITEL}" \
			--no-cancel \
			--inputbox "${1}" 5 45 "${SEARCH_PATTERN}" \
			3>&1 1>&2 2>&3 \
		)
	done

	# Get the exit status
	DIALOG_EXIT_STATUS=$?

	# Handle exit status
	case ${DIALOG_EXIT_STATUS} in
	$BUTTON_OK)
		# Handle dialog output
		SEARCH_PATTERN="$ANSWER"
		return 0
		;;
	$KEY_ESC)
		return 1
		;;
	esac
}

# -------------------------------
# FUNCTIION search_results ()
# run the search with the given pattern SEARCH_PATTERN 
# and show the results in a prgbox
# INPUT 
#     $1 ... label: textlabel of dialog
# RETURN:
#     0 ... okay
#     1 ... user pushed <ESC> key
# -------------------------------
function search_results {
	find "${SCAN_ARCHIVE_BASE_DIRECTORY}" -type f -name '*.json' \
		| xargs grep -h "title" \
		| grep -h -i "${SEARCH_PATTERN}" \
		| awk -F: '{ print $2 }' \
		| uniq | sort \
		> ./found.txt
	
	# Generate the dialog box
	ANSWER=$( \
		$DIALOG \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--no-cancel \
		--scrollbar \
		--editbox ./found.txt 18 65 \
		3>&1 1>&2 2>&3 \
	)

	# Get the exit status
	DIALOG_EXIT_STATUS=$?
	
	rm -f ./found.txt

	# Handle exit status
	case ${DIALOG_EXIT_STATUS} in
	$BUTTON_OK)
		return 0
		;;
	$KEY_ESC)
		return 1
		;;
	esac
}

# -------------------------------
# MAIN
# -------------------------------
ready=1
return=0

while [ $ready = 1 ] ; do
	get_search_pattern "Suchmuster?"
	return=$?
	
	if [ $return -eq $BUTTON_OK ] ; then
		search_results "Suchergebnisse"
		return=$?
	fi

	if [ $return -eq $BUTTON_OK ] ; then
		dialog \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--yesno "Suchergebnisse okay?" 0 0
		
		return=$?
		
		# <ESC> key pressed?
		if [ $return -eq $KEY_ESC ] ; then
			ready=0
		else
			ready=$return
		fi
	else
		ready=0
	fi
done

if [ $return -eq $BUTTON_OK ] ; then
	
	write_config
	exit 0
fi

#clear
echo "Abbruch durch Benutzer!"
exit 1
