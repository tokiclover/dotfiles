#
# $Header: ${HOME}/lib/promp-clover-setup.bash          Exp $
# $Author: (c) 2012-15 -tclover <tokiclover@gmail.com>  Exp $
# $License: 2-clause/new/simplified BSD                 Exp $
# $Version: 1.0 2015/06/25 21:09:26                     Exp $
#

# color: http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
function prompt-clover-setup {
	local TTY=$(tty | cut -b6-) uc
	case "${EUID}" in
		(0) uc="${fg[1]}";;
		(*) uc="${fg[2]}";;
	esac
	PS1="\[${color[bold]}${fg[5]}\]-\[${fg[4]}\](\[${uc}\]\$·\[${fg[5]}\]\h:${TTY}\[${fg[4]}\]·\D{%m/%d}·\[${fg[5]}\]\A\[${fg[4]}\])-\[${fg[2]}\]»\[${color[none]}\] "
	PS2="\[${color[bold]}${fg[5]}\]-\[${fg[2]}\]» \[${color[none]}\]"
	PROMPT_DIRTRIM=3
	TITLEBAR="\$:\w"
}
PROMPT_COMMAND=prompt-clover-setup

#
# vim:fenc=utf-8:ft=sh:ci:pi:sts=2:sw=2:ts=2:
#
