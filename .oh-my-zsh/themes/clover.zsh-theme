function precmd {
    local TERMWIDTH
    (( TERMWIDTH = $COLUMNS - 2 ))
    ##
    # Get VCS_INFO
    vcs_info
    ##
    # Truncate the path if it's too long.
    PR_FILLBAR=""
    PR_PWDLEN=""
    local promptsize=${#${(%):--(%n::%m/%l::%H:%M)--(${(%)vcs_info_msg_0_[1,15]})--}}
    local pwdsize=${#${(%):-%~}}
    if ((($promptsize+$pwdsize) > $TERMWIDTH)) { ((PR_PWDLEN=$TERMWIDTH-$promptsize))
    } else { PR_FILLBAR=\${(l.(($TERMWIDTH-($promptsize+$pwdsize)))..${PR_HBAR}.)} }
    ##
    # Get APM info.
    if [ which ibam &> /dev/null ]; then PR_APM_RESULT=$(ibam --percentbattery)
    elif [ which apm &> /dev/null ]; then PR_APM_RESULT=$(apm); fi
}

setopt extended_glob
preexec () {
    if [[ "$TERM" == "screen" ]] {
		local CMD=${1[(wr)^(*=*|sudo|-*)]}
		echo -n "\ek$CMD\e\\" }
}

setprompt () {
    ###
    # Need this so the prompt will work.
    setopt prompt_subst
    ###
    # See if we can use colors.
    autoload colors zsh/terminfo
    if [[ $terminfo[colors] -ge 8 ]] { colors }
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
		eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
		eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
		(( count = $count + 1 ))
	done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"
    ###
    # See if we can use extended characters to look nicer.
    typeset -A altchar
    set -A altchar ${(s..)terminfo[acsc]}
    PR_SET_CHARSET="%{$terminfo[enacs]%}"
    PR_SHIFT_IN="%{$terminfo[smacs]%}"
    PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
    PR_HBAR=${altchar[q]:--}
    PR_ULCORNER=${altchar[l]:--}
    PR_LLCORNER=${altchar[m]:--}
    PR_LRCORNER=${altchar[j]:--}
    PR_URCORNER=${altchar[k]:--}
    ###
    # Decide if we need to set titlebar text.
    case $TERM in
		xterm*|*rxvt*) 
		PR_TITLEBAR=$'%{\e]0;%(!.-*-ROOT-*-::.)%n@%m:%y:%~::${COLUMNS}x${LINES}\a%}';;
		screen) 
		PR_TITLEBAR=$'%{\e_screen:\005(\005t):%(!.-*ROOT*-::.)%n@%m:%y\a:%~::${COLUMNS}x${LINES}\a\e\\%}';;
		*) 	PR_TITLEBAR='';;
    esac
    ###
    # Decide whether to set a screen title
    if [[ $TERM == screen ]] { PR_STITLE=$'%{\ekzsh\e\\%}' } else { PR_STITLE='' }
    ###
    # APM detection
    if [ which ibam &> /dev/null ]; then
		PR_APM='$PR_RED${${PR_APM_RESULT[(f)1]}[(w)-2]}%%(${${PR_APM_RESULT[(f)3]}[(w)-1]})$PR_LIGHT_BLUE::'
    elif [ which apm &> /dev/null ]; then
		PR_APM='$PR_RED${PR_APM_RESULT[(w)5,(w)6]/\%:/%%}$PR_LIGHT_BLUE::'
    else PR_APM=''; fi
    ###
    # Finally, the prompt.
    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_LIGHT_MAGENTA$PR_SHIFT_IN$PR_ULCORNER$PR_LIGHT_BLUE$PR_HBAR$PR_SHIFT_OUT(\
$PR_MAGENTA%(!.%Sroot%s.%n)$PR_MAGENTA$PR_LIGHT_BLUE::$PR_MAGENTA%m:%l$PR_LIGHT_BLUE::$PR_MAGENTA\
${(e)PR_APM}$PR_LIGHT_MAGENTA%D{%H:%M}$PR_LIGHT_BLUE)$PR_SHIFT_IN$PR_HBAR$PR_MAGENTA\
$PR_HBAR${(e)PR_FILLBAR}$PR_LIGHT_BLUE$PR_HBAR$PR_SHIFT_OUT(\
$PR_MAGENTA%$PR_PWDLEN<...<%~%<<\
${(%)vcs_info_msg_0_[1,15]/::/$PR_BLUE::$PR_MAGENTA}$PR_LIGHT_BLUE\
)$PR_SHIFT_IN$PR_HBAR$PR_LIGHT_MAGENTA$PR_URCORNER$PR_SHIFT_OUT
$PR_LIGHT_MAGENTA$PR_SHIFT_IN$PR_LLCORNER$PR_LIGHT_BLUE$PR_HBAR$PR_SHIFT_OUT\
%(!.$PR_RED.$PR_GREEN)%#$PR_NO_COLOUR '

    RPROMPT=' $PR_LIGHT_MAGENTA$PR_SHIFT_IN$PR_HBAR$PR_LIGHT_BLUE$PR_HBAR$PR_SHIFT_OUT(\
%(?..$PR_LIGHT_RED%?$PR_RED:)$PR_GREEN%D{%a:%b:%d}$PR_LIGHT_BLUE\
)$PR_SHIFT_IN$PR_HBAR$PR_LIGHT_MAGENTA$PR_LRCORNER$PR_SHIFT_OUT$PR_NO_COLOUR'

    PS2='$PR_LIGHT_MAGENTA$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_LIGHT_BLUE$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT(\
$PR_LIGHT_GREEN%_$PR_LIGHT_BLUE)$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT\
$PR_LIGHT_MAGENTA$PR_SHIFT_IN$PR_HBAR$PR_SHIFT_OUT$PR_NO_COLOUR '
}

setprompt
