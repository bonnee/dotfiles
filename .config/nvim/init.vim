set runtimepath^=~/.config/nvim runtimepath+=~/.config/nvim/after
let &packpath = &runtimepath

"" General
set number relativenumber   " Show relative line numbers

"" https://jeffkreeftmeijer.com/vim-number/
augroup numbertoggle  " toggle number line style
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber
augroup END

set showbreak=+++	" Wrap-broken line prefix
"set textwidth=100	" Line wrap (number of cols)
set showmatch		" Highlight matching brace
set virtualedit=onemore	" Enable free-range cursor

set hlsearch	" Highlight all search results
set smartcase	" Enable smart-case search
set ignorecase	" Always case-insensitive
set incsearch	" Searches for strings incrementally
set mouse=a	" Enable mouse interaction

set autoindent	  " Auto-indent new lines
set shiftwidth=2  " Number of auto-indent spaces
set smartindent	  " Enable smart-indent
set smarttab	  " Enable smart-tabs
set softtabstop=2 " Number of spaces per Tab

set clipboard=unnamedplus  " nvim clipboard=system clipboard

"" Set cursor shape
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[2 q"
let &t_EI = "\<Esc>[2 q"

"" Advanced
set ruler	" Show row and column ruler information

set undolevels=1000	" Number of undo levels
set backspace=indent,eol,start	" Backspace behaviour

filetype on
syntax on

call plug#begin()

Plug 'neoclide/coc.nvim', {'branch': 'release'}

autocmd FileType json syntax match Comment +\/\/.\+$+

call plug#end()
