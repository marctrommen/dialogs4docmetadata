#!/usr/bin/env bash

source ./config
source ./config_handler.sh

# -------------------------------
# SETTING of variables
# -------------------------------
CURRENT_YEAR=$(date '+%Y')
YEAR=${CURRENT_YEAR}
MONTH=$(date '+%m')
DAY=$(date '+%d')
DATE="$YEAR$MONTH$DAY"
BACKTITEL="Dokumentarchivierung"
TITEL="Datum des Dokuments wählen"

# -------------------------------
# FUNCTIION preset_year ()
# let the user choose a year out of a range between 1975 and current year
# affects the variable YEAR
# INPUT
#     $1 ... year : max year
#     $2 ... year : selected year
#     $3 ... label: textlabel of dialog
# RETURN:
#     0 ... okay
#     1 ... user pushed <ESC> key
# -------------------------------
function preset_year {
	# Generate the dialog box
	ANSWER=$( \
		$DIALOG \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--no-cancel \
		--scrollbar \
		--no-items \
		--default-item ${2} \
		--menu "${3}" 15 30 8 \
		$(seq 1975 ${1} | sort -rd | tr '\n' ' ') \
		3>&1 1>&2 2>&3 \
	)

	# Get the exit status
	DIALOG_EXIT_STATUS=$?

	# Handle exit status
	case ${DIALOG_EXIT_STATUS} in
	$BUTTON_OK)
		# Handle dialog output
		YEAR=$ANSWER
		return 0
		;;
	$KEY_ESC)
		return 1
		;;
	esac
}

# -------------------------------
# FUNCTIION preset_month ()
# let the user choose a monthr out of a range between 1 and 12
# preset with current month
# affects the variable MONTH
# INPUT 
#     $1 ... month : current month
#     $2 ... label: textlabel of dialog
# RETURN:
#     0 ... okay
#     1 ... user pushed <ESC> key
# -------------------------------
function preset_month {
	# Generate the dialog box
	ANSWER=$( \
		$DIALOG \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--no-cancel \
		--scrollbar \
		--no-items \
		--default-item $(printf "%d" "${1}") \
		--menu "${2}" 15 30 8 \
		$(seq --separator=' ' 1 12) \
		3>&1 1>&2 2>&3 \
	)

	# Get the exit status
	DIALOG_EXIT_STATUS=$?

	# Handle exit status
	case ${DIALOG_EXIT_STATUS} in
	$BUTTON_OK)
		# Handle dialog output
		MONTH=$ANSWER
		return 0
		;;
	$KEY_ESC)
		return 1
		;;
	esac
}

# -------------------------------
# FUNCTIION get_date ()
# let the user choose a date from a calender
# preset with year, month, current day
# affects the variable DATE
# INPUT:
#     $1 ... year : YEAR
#     $2 ... month : MONTH
#     $3 ... day : current day
#     $4 ... label: textlabel of dialog
# RETURN:
#     0 ... okay
#     1 ... user pushed <ESC> key
# -------------------------------
function get_date {
	# Generate the dialog box
	ANSWER=$( \
		$DIALOG \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--no-cancel \
		--week-start 1 \
		--date-format "%Y%m%d" \
		--calendar "${4}" 0 0 ${3} ${2} ${1} \
		3>&1 1>&2 2>&3 \
	)

	# Get the exit status
	DIALOG_EXIT_STATUS=$?

	# Handle exit status
	case ${DIALOG_EXIT_STATUS} in
	$BUTTON_OK)
		DATE="${ANSWER}"
		return 0
		;;
	$KEY_ESC)
		return 1
		;;
	esac
}


# -------------------------------
# FUNCTIION get_document_id ()
# search in SCAN_ARCHIVE_BASE_DIRECTORY for next available directory
# named as SCAN_DOCUMENT_ID
# INPUT:
#     $1 ... date, formated as "YYYYMMDD"
# RETURN:
#     0 ... okay
#     1 ... SCAN_ARCHIVE_BASE_DIRECTORY is not available
#     2 ... maximum of 99 exceed
# -------------------------------
function get_document_id {
	local DATE="$1"
	
	# check for Scan Archive Directory
	if [ ! -d "${SCAN_ARCHIVE_BASE_DIRECTORY}" ]; then
		return 1
	fi
	
	for counter in $(seq 1 99); do
		SCAN_DOCUMENT_ID=$(printf "%s_%02d" "$DATE" $counter)
		if [ ! -d "${SCAN_ARCHIVE_BASE_DIRECTORY}/${SCAN_DOCUMENT_ID}" ]; then
			return 0
		fi
	done
	
	return 2
}

# -------------------------------
# MAIN
# -------------------------------
ready=1
return=0

while [ $ready = 1 ] ; do
	preset_year ${CURRENT_YEAR} ${YEAR} "Jahr?"
	return=$?
	
	if [ $return -eq $BUTTON_OK ] ; then
		preset_month ${MONTH} "Monat?"
		return=$?
	fi

	if [ $return -eq $BUTTON_OK ] ; then
		get_date ${YEAR} ${MONTH} ${DAY} "Datum?"
		return=$?
	fi

	if [ $return -eq $BUTTON_OK ] ; then
		dialog \
		--backtitle "${BACKTITEL}" \
		--title "${TITEL}" \
		--yesno "Gewähltes Datum\n\"$DATE\"\nokay?" 0 0
		
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
	echo "Gewähltes Datum: $DATE"
	
	get_document_id "$DATE"
	return=$?
	if [ $return -eq 0 ] ; then
		write_config
		SCAN_WORKING_DIRECTORY="${SCAN_ARCHIVE_BASE_DIRECTORY}/${SCAN_DOCUMENT_ID}"
		mkdir "${SCAN_WORKING_DIRECTORY}"
		echo "angelegtes Verzeichnis: ${SCAN_WORKING_DIRECTORY}"
		exit 0
	fi
	exit 1
fi

clear
echo "Abbruch durch Benutzer!"
exit 1
ll