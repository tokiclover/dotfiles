# $Id: $HOME/.zshrc,v 1.1 2011/11/04 -tclover Exp $

if [[ -f $HOME/.dir_colors ]] { eval $(dircolors -b $HOME/.dir_colors) 
} elif [[ -f /etc/DIR_COLORS ]] { eval $(dircolors -b /etc/DIR_COLORS) 
} else { eval $(dircolors) }
export ZLS_COLORS=$LS_COLORS
export FHP=$(print $HOME/.mozilla/firefox/*.default(/))
#export CDPATH='.:~:/var/dst/git-src:/var/dst/egit-src:/var/dst/svn-serc:/usr/src:/mnt'
export ZSH=$HOME/.oh-my-zsh
# Load all of the config files in ~/.oh-my-zsh that end in .zsh
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
for func ($fpath[1]/*) source $func

# Load all of the plugins that were defined in ~/.zshrc
for plugin ($plugins)
	if [[ -f $ZSH/custom/plugins/$plugin/$plugin.plugin.zsh ]] {
		source $ZSH/custom/plugins/$plugin/$plugin.plugin.zsh
	} elif [[ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]] {
		source $ZSH/plugins/$plugin/$plugin.plugin.zsh }

# vim:fenc=utf-8:ci:pi:sts=0:sw=2:ts=2:
