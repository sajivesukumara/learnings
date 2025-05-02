" File: sajive.vim
" Description: a colour scheme for Vim (GUI only)
" Scheme: sajive
" Maintainer: Sajive Kumar <sajive_kumar[at]mail.com>
" Comment: only works in GUI mode
" Version: v0.0.1
" Date: 25 Feb 2009
" History:
" 0.1.0 

" ------------------------------------------------------------------------------

highlight clear
"if exists("syntax_on")
"  syntax reset
"endif

let g:colors_name="sajive"

" ------------------------------------------------------------------------------
"guifg - foreground
"guibg - background
set background=dark
highlight!  Normal        guifg=white     guibg=black    gui=none
highlight!  Search        guifg=black     guibg=yellow     " hls part
highlight!  Visual	  term=reverse	cterm=reverse  gui=reverse
"highlight!  Visual        guifg=#0e1219   guibg=#6d5279    " esc+v / select
highlight!  Cursor        guifg=black      guibg=red       " cursor 
highlight!  Constant      guifg=cyan                       " String in quotes
highlight!  Comment       guifg=yellow                     " commented string
highlight   PreProc       guifg=blue      ctermfg=10       " Preprocessor directive
highlight!  Statement     guifg=gold        " if, return, switch-case,for,do
highlight   Error         guifg=red       guibg=orange

highlight! TabLine term=bold,reverse cterm=bold ctermfg=lightblue ctermbg=white gui=bold guifg=blue guibg=white
highlight! TabLineFill	term=bold,reverse cterm=bold ctermfg=lightblue ctermbg=white gui=bold guifg=blue guibg=white
highlight! TabLineSel term=reverse ctermfg=white ctermbg=lightblue guifg=white guibg=blue
highlight! StatusLine term=bold,reverse cterm=bold ctermfg=lightblue ctermbg=white gui=bold guifg=blue guibg=white
highlight! StatusLineNC term=reverse ctermfg=white ctermbg=lightblue guifg=white guibg=blue

"highlight!  StatusLine    guifg=cyan          guibg=#0e1219
"highlight!  CursorLine    guibg=#0e1219
"highlight!  CursorLine    guibg=#2c3138
"highlight!  PmenuSel      guifg=#0e1219       guibg=yellow  "#8b9aaa
"highlight!  IncSearch     guifg=#0e1219       guibg=#2680af
"highlight!  LineNr        guifg=#2c3138       guibg=#0e1219
"highlight!  NonText       guifg=gold  
"highlight!  Todo          guifg=#82ade0       guibg=#0e1219
"highlight!  Todo          guisp=#2680af       gui=bold,undercurl
"highlight!  Underlined    gui=bold,underline
"highlight!  Pmenu         guifg=#8b9aaa       guibg=#2c3138
"highlight!  StatusLineNC  guifg=#2c3138       guibg=#8b9aaa
"highlight!  VertSplit     guifg=#2c3138       guibg=#8b9aaa
