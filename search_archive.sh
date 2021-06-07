#!/usr/bin/env bash

source ./config
source ./config_handler.sh

# -------------------------------
# SETTING of variables
# -------------------------------
BACKTITEL="Dokumentarchivierung"
TITEL="Textmuster in Metadaten suchen"
SEARCH_PATTERN=""
CLIPBOARD=/usr/bin/clipit


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
	local ANSWER=""
	
	# Generate the dialog box
	ANSWER=$( \
		$DIALOG \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--no-cancel \
		--inputbox "${1}" 5 45 "${SEARCH_PATTERN}" \
		3>&1 1>&2 2>&3 \
	)

	# Get the exit status
	DIALOG_EXIT_STATUS=$?

	# Handle exit status
	if [ ${DIALOG_EXIT_STATUS} -eq $BUTTON_OK ]; then
		# Handle dialog output
		SEARCH_PATTERN="$ANSWER"
		return 0
	fi
	
	SEARCH_PATTERN=""
	return 1
}


# -------------------------------
# FUNCTIION search_results ()
# run the search with the given pattern SEARCH_PATTERN 
# and pipe the results into less
# INPUT 
#     none
# RETURN:
#     0 ... okay
#     1 ... user pushed <ESC> key
# -------------------------------
function search_results {
	SCAN_DOCUMENT_TITLE=""
	
	find "${SCAN_ARCHIVE_BASE_DIRECTORY}" -type f -name '*.json' \
		| xargs grep -h "title" \
		| grep -h -i "${SEARCH_PATTERN}" \
		| awk -F: '{ print $2 }' \
		| sort --unique \
		| less
	
	# Get the exit status
	DIALOG_EXIT_STATUS=$?
	
	# Handle exit status
	if [ ${DIALOG_EXIT_STATUS} -eq $BUTTON_OK ]; then
		which ${CLIPBOARD}
		return=$?
		if [ $return -eq 0 ]; then
			SCAN_DOCUMENT_TITLE=$(${CLIPBOARD} -c)
			return 0
		fi
	fi

	return 1
}


# -------------------------------
# FUNCTIION set_document_title ()
# let the user enter text for the metadata document title.
# affects the variable SCAN_DOCUMENT_TITLE
# INPUT
#     $1 ... label: textlabel of dialog
# RETURN:
#     0 ... okay
#     1 ... user pushed <ESC> key
# -------------------------------
function set_document_title {
	local ANSWER=""
	
	while [ -z "${ANSWER}" ]; do
		# Generate the dialog box
		ANSWER=$( \
			$DIALOG \
			--backtitle "${BACKTITEL}" \
			--title "${TITEL}" \
			--no-cancel \
			--inputbox "${1}" 0 0 "${SCAN_DOCUMENT_TITLE}" \
			3>&1 1>&2 2>&3 \
		)
	
		# Get the exit status
		DIALOG_EXIT_STATUS=$?

		# Handle exit status
		if [ ${DIALOG_EXIT_STATUS} -eq $BUTTON_OK ]; then
			# Handle dialog output
			SCAN_DOCUMENT_TITLE="$ANSWER"
			return 0
		fi
	done
	
	return 1
}

# -------------------------------
# MAIN
# -------------------------------
ready=1
return=0

while [ $ready = 1 ]; do
	# search in the meta data of the docarchive?
	get_search_pattern "Suchmuster?"
	return=$?
	
	if [ $return -eq $BUTTON_OK ]; then
		# do a text search only if SEARCH_PATTERN is not empty
		if [ "${SEARCH_PATTERN}" != "" ] ; then
			search_results
			return=$?
		fi
	fi

	if [ $return -eq $BUTTON_OK ]; then
		set_document_title "Dokumenttitel / Betreff? *\n\nDarf nicht leer sein!\n"
		return=$?
	fi
	
	if [ $return -eq $BUTTON_OK ]; then
		dialog \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--yesno "Dokumenttitel okay?" 0 0
		
		return=$?
		
		# <ESC> key pressed?
		if [ $return -eq $KEY_ESC ]; then
			ready=0
		else
			ready=$return
		fi
	else
		ready=0
	fi
done

if [ $return -eq $BUTTON_OK ]; then
	echo "Gewählter Dokumenttitel:"
	echo "${SCAN_DOCUMENT_TITLE}"
	write_config
	exit 0
fi

#clear
echo "Abbruch durch Benutzer!"
SCAN_DOCUMENT_TITLE=""
write_config
exit 1
