#!/bin/bash
#
# $Id: termcolors.bash, 2014/07/31 -tclover Exp $
# $License: MIT (or 2-clause/new/simplified BSD) Exp $

declare C E="\e[" T=ABC
declare B="${E}48;5" F="38;5" R="${E}0m"
declare -a CLR
CLR=(BLK RED GRN YEL BLU MAG CYN WHT)

echo -en "\n             "
for (( i=0; i<8; i++ )); do
	echo -en "${CLR[$i]}     "
done
echo

printline() {
	echo -en " ${CLR[$i]} ${E}${1}3${i}  ${T}  "
	for (( j=0; j<8; j++ )); do
		echo -en " ${E}${1}3${i}${E}${1}4${j}  ${T}  ${R}"
	done
	echo
}

for (( i=0; i<8; i++ )); do
	printline
	printline "1;"
done
	
# vim:fenc=utf-8:ci:pi:sts=0:sw=4:ts=4:
