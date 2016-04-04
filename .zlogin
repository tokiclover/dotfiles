
# $Header: ${HOME}/.zlogin                              Exp $
#

# auto startx depending on the tty
if [[ -z $DISPLAY ]] && [[ $EUID != 0 ]] {
	[[ ${TTY/tty} != $TTY ]] && (( ${TTY:8:1} <= 3 )) &&
		startx 1>~/.log/xsession.log 2>&1 &
}

# Start ssh-agent
if [[ -r $TMPDIR/env ]] {
	while read line; do
		export $line
	done <$TMPDIR/env
} else {
	eval export $(gpg-agent --daemon --sh)
	eval export $(ssh-agent -s)
	{
		echo GPG_AGENT_INFO=$GPG_AGENT_INFO
		echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK
		echo SSH_AGENT_PID=$SSH_AGENT_PID
	} >$TMPDIR/env
}

#
# vim:fenc=utf-8:ci:pi:sts=2:sw=2:ts=2:
#
