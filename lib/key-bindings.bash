#
# $Header: ${HOME}/.bash/lib/key-bindings.bash          Exp $
#
# This is an extended numeric pad keys mapping when <num_lock>
# is unset. The last are combination of <R_S>|<R_C>+[(A|B|C|D)
#
# $Author: (c) 2012-15 -tclover <tokiclover@gmail.com>  Exp $
# $License: 2-clause/new/simplified BSD                 Exp $
# $Version: 2015/05/15 21:09:26                         Exp $
#

#
# Set up a few options
#
set enable-keypad On
set enable-meta-key On
set mark-modified-lines On
#
# Meta options
#
set meta-flag On
set input-meta On
set convert-meta On
set output-meta On
#
# Set up a few completion options
#
set colored-stats On
set mark-directories On
set page-completions On
set menu-complete-display-prefix On

function tput-to-str {
	strace -s 64 -e trace=write tput ${@} 2>&1 | sed -nre 's/.*"([^"].*33)(.*)".*/\\e\2/p'
}

#
# Set up keyinfo associative array
#
typeset -A keyinfo
for key in 'Control:\C-' 'Escape:\e' 'Meta:\M-' 'Backspace:^?' 'Delete:\e[3~' \
	'Up:\e[A' 'Left:\e[D' 'Down:\e[B' 'Right:\e[C'; do
	keyinfo[${key%:*}]="${key#*:}"
done
for key in 'F1:kf1' 'F2:kf2' 'F3:kf3' 'F4:kf4' 'F5:kf5' 'F6:kf7' \
	'F7:kf7' 'F8:kf8' 'F9:kf9' 'F10:kf10' 'F11:kf11' 'F12:kf12' 'Insert:kich1' \
	'Home:khome' 'PageUp:kpp' 'End:kend' 'PageDown:knp' 'BackTab:kcbt'; do
	keyinfo[${key%:*}]="$(tput-to-str ${key#*:})"
done

bind "\"${keyinfo[Backspace]}\"":backward-delete-char
bind "\"${keyinfo[Home]}\"":beginning-of-line
bind "\"${keyinfo[End]}\"":end-of-line
bind "\"${keyinfo[PageUp]}\"":up-line-or-history
bind "\"${keyinfo[PageDown]}\"":down-line-or-history
bind "\"${keyinfo[Delete]}\"":delete-char

if [[ "${DISPLAY}" ]]; then
	function print-screen {
		import -window root "${HOME}"/shot-$(date '+%Y-%m-%d-%H-%M-%S').png
	}
	function run-term { urxvtc; }
else
	function print-screen {
		fbgrab -c $(tty) -z 9 "${HOME}"/shot-$(date '+%Y-%m-%d-%H-%M-%S').png
	}
	function run-term { screen; }
fi

#
# Define a few functions equivalent to ACPI key events
#
for cmd in volume{down,mute,up}; do
	eval "function ACPI-${cmd} { /etc/acpi/default.sh button/${cmd}; }"
done
for cmd in next pause play prev stop; do
	eval "function ACPI-CD-${cmd} { /etc/acpi/default.sh cd/${cmd}; }"
done

bind -x "\"${keyinfo[F8]}\"":print-screen
bind -x "\"${keyinfo[F9]}\"":run-term
bind -x "\"${keyinfo[F10]}\"":ACPI-volumemute
bind -x "\"${keyinfo[F11]}\"":ACPI-volumedown
bind -x "\"${keyinfo[F12]}\"":ACPI-volumeup

case "${TERM}" in
	(rxvt*|screen*)
for key in emacs-standard vi-insert; do
	bind -m "${key}" '"\eOw":beginning-of-line'
	bind -m "${key}" '"\eOq":end-of-line'
	bind -m "${key}" '"\eOt":backward-char'
	bind -m "${key}" '"\eOv":forward-char'

	bind -m "${key}" '"\eOr":down-line-or-history'
	bind -m "${key}" '"\eOs":end-of-history'
	bind -m "${key}" '"\eOx":up-line-or-history'
	bind -m "${key}" '"\eOy":beginning-of-history'

	bind -m "${key}" '"\eOn":backward-delete-char'
	bind -m "${key}" '"\eOp":vi-cmd-mode'
	bind -m "${key}" '"\eOu":delete-char'
	bind -m "${key}" '"\eOM":accept-line'

	bind -m "${key}" '"\eOa":undo'
	bind -m "${key}" '"\eOb":redo'
	bind -m "${key}" '"\eOc":forward-word'
	bind -m "${key}" '"\eOd":backward-word'

	#
	# key bindings with CTRL key--C-F<n> for mpd/mpc
	#
	bind -x "\"${keyinfo[F9]/\~/^}\"":ACPI-CD-pause
	bind -x "\"${keyinfo[F10]/\~/^}\"":ACPI-CD-play
	bind -x "\"${keyinfo[F11]/\~/^}\"":ACPI-CD-next
	bind -x "\"${keyinfo[F12]/\~/^}\"":ACPI-CD-prev
done
set enable-bracketed-paste On
	;;
	(xterm*)
for key in emacs-standard vi-insert; do
	bind -m "${key}" '"\E[H":beginning-of-line'
	bind -m "${key}" '"\E[F":end-of-line'

	#
	# key bindings with CTRL key--C-F<n> for mpd/mpc
	#
	bind -x "\"${keyinfo[F9]/\~/;5~}\"":ACPI-CD-pause
	bind -x "\"${keyinfo[F10]/\~/;5~}\"":ACPI-CD-play
	bind -x "\"${keyinfo[F11]/\~/;5~}\"":ACPI-CD-next
	bind -x "\"${keyinfo[F12]/\~/;5~}\"":ACPI-CD-prev
done
set enable-bracketed-paste On
	;;
esac
#
# Set the same bindings with standard keys
#
for key in emacs-standard vi-insert; do
	bind -m "${key}" '"\e[a":copy-earlier-word'
	bind -m "${key}" '"\e[b":backward-kill-line'
	bind -m "${key}" '"\e[c":backward-kill-word'
	bind -m "${key}" '"\e[d":kill-word'

	bind -m "${key}" '"\C-[A":undo'
	bind -m "${key}" '"\C-[B":redo'
	bind -m "${key}" '"\C-[C":forward-word'
	bind -m "${key}" '"\C-[D":backward-word'

	bind -m "${key}" "\"\C-L\"":clear-screen
done
unset cmd key

case "${EDITOR}" in
	(*vi) set -o vi ;;
	(*) set -o emacs;;
esac

#
# vim:fenc=utf-8:tw=80:sw=2:sts=2:ts=2:
#
