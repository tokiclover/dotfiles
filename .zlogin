
# $Id: ~/.zlogin                              Exp $
#

# auto startx depending on the tty
if [[ -z $DISPLAY ]] && [[ $EUID != 0 ]] {
	[[ ${TTY/tty} != $TTY ]] && (( ${TTY:8:1} <= 3 )) &&
		startx 1>~/.log/xsession.log 2>&1 &
}

# Start ssh-agent
envfile=$TMPDIR/ssh-agent-env
if [[ -r $envfile ]] {
	while read line; do
		export $line
	done <$envfile
} else {
	eval export $(gpg-agent --homedir ~/.gnupg --use-standard-socke --daemon --sh)
	eval export $(ssh-agent -s)
	printf "GPG_AGENT_INFO=$GPG_AGENT_INFO\nSSH_AUTH_SOCK=$SSH_AUTH_SOCK\nSSH_AGENT_PID=$SSH_AGENT_PID\n" >$envfile
}
unset envfile

#
# vim:fenc=utf-8:ci:pi:sts=2:sw=2:ts=2:
#
