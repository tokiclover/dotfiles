# $Id: $HOME/.zshrc,v 1.1 2011/09/11 -tclover Exp $
#
# That this file is used by any Bourne-shell derivative to setup the
# environment for login shells.
#

# Load environment settings from profile.env, which is created by
# env-update from the files in /etc/env.d
[[ -e /etc/profile.env ]] && . /etc/profile.env
# You should override these in your $HOME/.bashrc (or equivalent) for per-user
# settings.  For system defaults, you can add a new file in /etc/profile.d/.
export EDITOR=${EDITOR:-/bin/nano}
export PAGER=${PAGER:-/usr/bin/less}

# 077 would be more secure, but 022 is generally quite realistic
umask 022

if [[ "$EUID" = "0" ]] || [[ "$USER" = "root" ]]; then
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${ROOTPATH}"
else	PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"
	[[ -e $HOME/scr/addt.sh ]] && function adt() { . $HOME/scr/adt; }
	[[ -e $HOME/scr/ffp-pack ]] && function ffp() { . $HOME/scr/ffp-pack; }; fi
export PATH
unset ROOTPATH

for sh in /etc/profile.d/*.sh; do [ -r "$sh" ] && . "$sh"; done

[[ -f $HOME/.aliasrc ]] && . $HOME/.aliasrc
if [[ -f $HOME/.dir_colors ]]; then eval $(dircolors -b $HOME/.dir_colors)
elif [[ -f /etc/DIR_COLORS ]]; then eval $(dircolors -b /etc/DIR_COLORS)
else eval $(dircolors); fi

export ZSH=$HOME/.oh-my-zsh
# Load all of the config files in ~/oh-my-zsh that end in .zsh
# TIP: Add files you don't want in git to .gitignore
for config_file ($ZSH/lib/*.zsh) source $config_file

# Load and run compinit
autoload -U promptinit 
promptinit -i
source $ZSH/themes/clover.zsh-theme

autoload -Uz vcs_info
#zstyle ':vcs_info:*' disable bzr cdv darcs mtn svk tla
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:*' actionformats '%a'
zstyle ':vcs_info:*' formats       '::%s:%b%u'
zstyle ':vcs_info:(git|svn):*' branchformat '%b'

setopt EXTENDED_GLOB
plugins=(zsh-syntax-highlighting)

# Add all defined plugins to fpath
plugin=${plugin:=()}
for plugin ($plugins) fpath=($ZSH/plugins/$plugin $fpath)

# add a function path
fpath=($ZSH/functions $ZSH/completions $fpath)

# Load all of the plugins that were defined in ~/.zshrc
for plugin ($plugins); do
  if [ -f $ZSH/custom/plugins/$plugin/$plugin.plugin.zsh ]; then
    source $ZSH/custom/plugins/$plugin/$plugin.plugin.zsh
  elif [ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]; then
    source $ZSH/plugins/$plugin/$plugin.plugin.zsh
  fi
done

