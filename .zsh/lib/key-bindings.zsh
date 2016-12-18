#
# $Header: ${HOME}/.zsh/lib/key-bindings.zsh            Exp $
#
# This is an extended numeric pad keys mapping when <num_lock>
# is unset. The last are combination of <R_S>|<R_C>+[(A|B|C|D)
#
# $Author: (c) 2012-15 -tclover <tokiclover@gmail.com>  Exp $
# $License: MIT (or 2-clause/new/simplified BSD)        Exp $
# $Version: 2015/06/20 21:09:26                         Exp $
#

if (( ${+DISPLAY} )); then
	function print-screen {
		import -window root ${HOME}/shot-$(date '+%Y-%m-%d-%H-%M-%S').png
	}
	function run-term { urxvtc }
else
	function print-screen {
		fbgrab -c ${TTY} -z 9 ${HOME}/shot-$(date '+%Y-%m-%d-%H-%M-%S').png
	}
	function run-term { screen }
fi

#
# Define a few functions equivalent to ACPI key events
#
for cmd (volume{down,mute,up}) {
	eval function ACPI-${cmd} \{ /etc/acpi/default.sh button/${cmd} \}
	zle -N ACPI-${cmd}
}
for cmd (next pause play prev stop) {
	eval function ACPI-CD-${cmd} \{ /etc/acpi/default.sh cd/${cmd} \}
	zle -N ACPI-CD-${cmd}
}

zle -N run-term
zle -N print-screen
autoload -Uz copy-earlier-word
zle -N copy-earlier-word

case ${TERM} {
	(rxvt*|screen*)
bindkey -s '\EOa' '\C-[A'
bindkey -s '\EOb' '\C-[B'
bindkey -s '\EOc' '\C-[C'
bindkey -s '\EOd' '\C-[D'

for key (emacs viins) {
	bindkey -M ${key} "\EOw" beginning-of-line
	bindkey -M ${key} "\EOq" end-of-line
	bindkey -M ${key} "\EOt" backward-char
	bindkey -M ${key} "\EOv" forward-char

	bindkey -M ${key} "\EOr" down-line-or-history
	bindkey -M ${key} "\EOs" end-of-history
	bindkey -M ${key} "\EOx" up-line-or-history
	bindkey -M ${key} "\EOy" beginning-of-history

	bindkey -M ${key} "\EOn" backward-delete-char
	bindkey -M ${key} "\EOp" vi-cmd-mode
	bindkey -M ${key} "\EOu" delete-char
	bindkey -M ${key} "\EOM" accept-line

	#
	# key bindings with CTRL key--C-F<n> for mpd/mpc
	#
	bindkey -M ${key} "${terminfo[kf12]/\~/^}" ACPI-CD-prev
	bindkey -M ${key} "${terminfo[kf11]/\~/^}" ACPI-CD-next
	bindkey -M ${key} "${terminfo[kf10]/\~/^}" ACPI-CD-play
	bindkey -M ${key} "${terminfo[kf9]/\~/^}"  ACPI-CD-pause
}
	;;
	(xterm*)
for key (emacs viins) {
	bindkey -M ${key} "\E[H"  beginning-of-line
	bindkey -M ${key} "\E[F"  end-of-line

	#
	# key bindings with CTRL key--C-F<n> mpd/mpc
	#
	bindkey -M ${key} "${terminfo[kf12]/\~/;5~}" ACPI-CD-prev
	bindkey -M ${key} "${terminfo[kf11]/\~/;5~}" ACPI-CD-next
	bindkey -M ${key} "${terminfo[kf10]/\~/;5~}" ACPI-CD-play
	bindkey -M ${key} "${terminfo[kf9]/\~/;5~}"  ACPI-CD-pause
}
	;;
esac
#
# Set the same bindings with standard keys
#
for key (emacs viins) {
	bindkey -M ${key} "\E[a" copy-earlier-word
	bindkey -M ${key} "\E[b" backward-kill-line
	bindkey -M ${key} "\E[c" backward-kill-word
	bindkey -M ${key} "\E[d" kill-word

	bindkey -M ${key} "\C[A" undo
	bindkey -M ${key} "\C[B" redo
	bindkey -M ${key} "\C[C" forward-word
	bindkey -M ${key} "\C[D" backward-word

	bindkey -M ${key} "\C-[A" undo
	bindkey -M ${key} "\C-[B" redo
	bindkey -M ${key} "\C-[C" forward-word
	bindkey -M ${key} "\C-[D" backward-word

	bindkey -M ${key} "${terminfo[kf12]}" ACPI-volumeup
	bindkey -M ${key} "${terminfo[kf11]}" ACPI-volumedown
	bindkey -M ${key} "${terminfo[kf10]}" ACPI-volumemute
	bindkey -M ${key} "${terminfo[kf8]}"  run-term
	bindkey -M ${key} "${terminfo[kf9]}"  print-screen
}
unset cmd key

#
# vim:fenc=utf-8:tw=80:sw=2:sts=2:ts=2:
#
