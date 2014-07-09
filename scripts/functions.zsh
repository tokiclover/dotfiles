# $Id: $HOME/scripts/functions.zsh,v 2014/07/07 10:59:26 -tclover Exp $

# @FUNCTION: error
# @DESCRIPTION: hlper function, print message to stdout
# @USAGE: <string>
error() {
	$LOG && logger -p $facility.err -t ${(%):-%1x}: $@
	print -P "${(%):-%1x}: ${(%):-%1x}: %B%F{red}*%b%f $@"
}

# @FUNCTION: die
# @DESCRIPTION: hlper function, print message and exit
# @USAGE: <string>
function die() {
  local ret=$?
  print -P "%F{red}*%f $@"
  exit $ret
}

# @FUNCTION: info
# @DESCRIPTION: hlper function, print message to stdout
# @USAGE: <string>
info() {
	$LOG && logger -p $facility.err -t ${(%):-%1x}: $@
	print -P "${(%):-%1x}: %B%F{green}*%b%f $@"
}

# vim:fenc=utf-8:ft=zsh:ci:pi:sts=0:sw=2:ts=2:
