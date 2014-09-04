#!/bin/bash
#
# $Id: term256colors.bash, 2014/07/31 -tclover      Exp $
# $License: MIT (or 2-clause/new/simplified BSD)    Exp $
#
# $Original: http://frexx.de/xterm-256-notes/data/colortable16.sh

printline() {
    echo "     ----------------------------------------------------------------------------"
}

declare BO FO C E="\e["
declare B="${E}48;5" F="38;5" R="${E}m"

C=$(tput colors)
[[ $C -lt 256 ]] && echo "256 colors not supported" >&2 && exit 1

declare -a CLR
CLR=(DFT BLK RED GRN YEL BLU MAG CYN WHT)

while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--bg-offset)
            BO=$2
            shift 2;;
        -f|--fo-offset)
            FO=$2
            shift 2;;
        *)
            echo "unrecognized option" >&2
            echo "usage: ${0##*/} [-b|--bg-offset <offset>] [-f|--fg-offset <offset>]"
            exit 1;;
    esac
done

[[ -n "$BO" ]] && ( (( $BO <= (256-8) )) || BO=0 )
[[ -n "$FO" ]] && ( (( $FO <= (256-8) )) || FO=0 )

printline
for (( b=0; i<8; i++ )); do
	echo -en "$R ${CLR[$b]} : "
	for (( f=0; f<8; f++ )); do
		echo -en "${B};$(($b+$BO))m${E}${F};$(($f+$FO))m ${CLR[$(($f+1))]} "
	done

	echo -en "$R :"
	echo -en "$R\n$R     : "
	for (( f=0; f<8; f++ )); do
		echo -en "${B};$(($b+$BO))m${E}1;${F};$(($f+$FO))m ${CLR[$(($f+1))]} "
	done

	echo -en "$R :"
	echo -e "$R"
	printline
done
printline

unset B BO CLR E F FO R

# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
