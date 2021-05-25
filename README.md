# dialogs4docmetadata
First attempt to use Bash Dialog for user interaction. Guides user collecting metadata for scanning a documents.


[![MIT License][LICENSE-BADGE]](LICENSE)
![Linux][LINUX-BADGE]
![Bash 4][Bash-BADGE]


[LICENSE-BADGE]: https://img.shields.io/badge/license-MIT-blue.svg
[LINUX-BADGE]: https://img.shields.io/badge/Linux-blue.svg
[Bash-BADGE]: https://img.shields.io/badge/Bash-4-blue.svg


## Links

*	[linuxcommand.org: dialog](https://linuxcommand.org/lc3_adv_dialog.php)
*	[Manpage dialog](https://invisible-island.net/dialog/manpage/dialog.html)
*	[Linux Gazette: Designing Simple front ends with dialog/Xdialog](https://linuxgazette.net/101/sunil.html)
*	[linux-community: mehr Komfort mit Dialog](https://www.linux-community.de/ausgaben/linuxuser/2014/03/mehr-komfort/2/)
*	[Dialog `buildlist` Beispiel](https://stackoverflow.com/questions/44445741/dialog-buildlist-option-how-to-use-it)
*	[Dialog Script-Beispiele](https://github.com/ThomasDickey/dialog-snapshots/tree/master/samples)
*	[UbuntuUsers: Dialog Bash GUI](https://wiki.ubuntuusers.de/Dialog/)
*	[UbuntuUsers: Dialog-Optionen](https://wiki.ubuntuusers.de/Howto/Dialog-Optionen/)
*	[Rheinwerk: Dialog](https://openbook.rheinwerk-verlag.de/shell_programmierung/shell_007_007.htm)
*	[Wikipedia: Zeichenorientierte Benutzerschnittstelle](https://de.wikipedia.org/wiki/Zeichenorientierte_Benutzerschnittstelle)

## Exit-Codes

Button / Taste | Exit-Code (`$?`) | RETURN-Value
------------------------------------------------
OK             | 0                | value
Yes            | 0                | -
No             | 1                | -
Cancel         | 1                | -
<Ctrl> + C     | 1                | -
Help           | 2                | HELP value
Extra          | 3                | value
<ESC>          | 255              | -


```
--exit-label string
--default-button string --> ok, yes, cancel, no, help, extra
--extra-button
--extra-label string
--help-button
--help-label string
--no-cancel
--no-label string
--no-ok
--ok-label
--yes-label
```

## Umlekung der File-Deskriptoren

### Alternative 1: `exec`

```
# create a backup copy of file descriptor 1 (STDOUT) on descriptor 3
#exec 3>&1

# Generate the dialog box
ANSWER=$($DIALOG ... \
    2>&1 1>&3 )

# Get the exit status
DIALOG_EXIT_STATUS=$?

# Close file descriptor 3
exec 3>&-

echo "${ANSWER}"
```

### Alternative 2: redirection

```
# Generate the dialog box
ANSWER=$($DIALOG ... \
    3>&1 1>&2 2>&3 )

# Get the exit status
DIALOG_EXIT_STATUS=$?

echo "${ANSWER}"
```
