" $Id: ~/.vimrc, 2014/07/31 -tclover Exp $
" ------------------------------------------------- HEAD
" simple and sane vimrc based on https://github.com/W4RH4WK/dotVim/
" gentoo has a rich app-vim category, so take a look at
" cfg/etc/portage/sets/vim for my sets of vim plugins

set nocompatible

" -------------------------------------------------- BEFORE
for f in split(glob('~/.vim/before/*.vim'), '\n')
	source f
endfor

" -------------------------------------------------- GLOBAL
if filereadable("/etc/vim/vimrc")
	source /etc/vim/vimrc
endif

" -------------------------------------------------- LOCAL
if filereadable("~/.vim/vimrc")
	source ~/.vim/vimrc
endif

" -------------------------------------------------- PATHOGEN
call pathogen#infect('/usr/share/vim/vim74/plugin/{}')
call pathogen#infect('/usr/share/vim/vimfiles/plugin/{}')
call pathogen#infect('~/.vim/plugin/{}')

" -------------------------------------------------- PLUGIN
let g:yankring_history_dir='~/.vim/runtime'

" -------------------------------------------------- BASICS
" settings
scriptencoding utf-8
set bs=2
set history=50
set ruler

filetype off

syntax on
set shell=zsh

" handling
set backspace=indent,eol,start
set foldignore=" "
set foldmethod=indent
set formatoptions=cqrt
set ignorecase
set incsearch
set smartcase
set timeoutlen=500

" visual
set background=dark
set encoding=utf-8
set laststatus=2
set lazyredraw
set listchars=tab:>\ ,eol:\
set nohlsearch
set nowrap
set ruler
set showcmd
set ttyfast

" visual gui
set antialias
set background=dark
set guifont=Terminus\ 8
set guioptions=aegi
set mousehide
set noerrorbells

" file handling
set fileencoding=utf-8
set history=50
set modeline
set noswapfile
set tags=./.tags;/
set viminfo="NONE"

" formating
set autoindent    " automatically indent lines
set expandtab     " use spaces to indent
set shiftwidth=4  " number of spaces for indent
set smarttab      " backspace over tabs
set softtabstop=4 " tab = softtabstop * spaces
set tabstop=4     " tab stop distance

" set omnifunc
autocmd FileType c set omnifunc=ccomplete#Complete
autocmd FileType css set omnifunc=csscomplete#CompleteCSS
autocmd FileType html set omnifunc=htmlcomplete#CompleteTags
autocmd FileType php set omnifunc=phpcomplete#CompletePHP
autocmd FileType python set omnifunc=pythoncomplete#Complete
autocmd FileType xml set omnifunc=xmlcomplete#CompleteTags
set completeopt=menu

" -------------------------------------------------- COLOR
if $TERM == 'linux'
    set t_Co=8
    set colorcolumn=0
    colorscheme torte
else
    set t_Co=256
    set colorcolumn=80
    colorscheme wombat256mod
endif

" -------------------------------------------------- KEYBINDINGS
" disable forward / backward (tmux)
"noremap <c-b> <NOP>
"noremap <c-f> <NOP>

" redraw screen
nnoremap <leader>r <ESC>:redraw!<CR>

" save as root
nnoremap <leader>w <ESC>:w !sudo tee % > /dev/null<CR>

" tab switch
nnoremap <Tab> <ESC>:tabn<CR>
nnoremap <S-Tab> <ESC>:tabp<CR>

" toggle paste mode
set pastetoggle=<F2>

" trim trailing whitespace
nnoremap <leader>t <ESC>:%s/\s\+$//<CR>

" window movement
nnoremap <c-h> <c-w>h
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-l> <c-w>l

nnoremap <S-Tab> <ESC>:tabp<CR>

" toggle paste mode
set pastetoggle=<F2>

" trim trailing whitespace
nnoremap <leader>t <ESC>:%s/\s\+$//<CR>

" window movement
nnoremap <c-h> <c-w>h
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-l> <c-w>l

" vim:fenc=utf-8:tw=80:sw=2:sts=2:ts=2:
