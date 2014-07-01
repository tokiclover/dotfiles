# $Id: $HOME/.scripts/functions.bash,v 2014/07/01 09:59:26 -tclover Exp $

# @FUNCTION: die
# @DESCRIPTION: hlper function
# @USAGE: <string>
die() {
	local _ret=$?
	echo "* $@"
	exit $_ret
}

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
