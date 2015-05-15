#!/bin/bash
#
# terminal 256 colors display script
#
# $Header: ${HOME}/bin/term256colors.bash                   Exp $
# $Author: (c) 2014-15 -tclover <tokiclover@gmail.com>      Exp $
# $License: MIT (or 2-clause/new/simplified BSD)            Exp $
# $Version: 1.0 2015/05/15                              Exp $
# $Screenhots: https://imgur.com/EqE6iOz.png                Exp $
#
# $Original: http://frexx.de/xterm-256-notes/data/colortable16.sh

function pr-line {
	echo "     >------------------------------------------<"
}

declare BO=0 FO=0 E="\e["
declare B="${E}48;5" F="38;5" R="${E}0m"
(( $(tput colors) < 256 )) && echo "256 colors not supported" >&2 && exit 1

declare -a CLR
CLR=(DFT BLK RED GRN YEL BLU MAG CYN WHT)

while (( $# > 0 )); do
	case $1 in
		(-b|--bg-offset) BO=$2;;
		(-f|--fo-offset) FO=$2;;
		(*)
			echo "Unrecognized option" >&2
			echo "usage: ${0##*/} [-b|--bg-offset OFFSET] [-f|--fg-offset OFFSET]"
			exit 2;;
	esac
	shift 2
done

(( $BO <= (256-8) )) || BO=0
(( $FO <= (256-8) )) || FO=0

pr-line
for (( b=0; i<8; i++ )); do
	echo -en "$R ${CLR[$b]} : "
	for (( f=0; f<8; f++ )); do
		echo -en "${B};$(($b+$BO))m${E}${F};$(($f+$FO))m ${CLR[$(($f+1))]} "
	done

	echo -en "$R :"
	echo -en "$R\n$R     : "
	for (( f=0; f<8; f++ )); do
		echo -en "${B};$(($f+$BO))m${E}1;${F};$(($f+$FO))m ${CLR[$(($f+1))]} "
	done

	echo -en "$R :"
	echo -e "$R"
	pr-line
done

unset B BO CLR E F FO R

#
# vim:fenc=utf-8:ci:pi:sts=2:sw=2:ts=2:
#
