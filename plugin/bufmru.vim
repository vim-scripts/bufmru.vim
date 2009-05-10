" bufmru - switch to most recently used buffers
" File:         bufmru.vim
" Vimscript:	#2346
" Created:      2008 Aug 18
" Last Change:  2009 May 08
" Rev Days:     34
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	2.7 (wildmenu only)
" License:	Vim license

" Comments

" Description: {{{1
"   Switch between MRU buffers from the current session. Like CTRL-^, but
"   reach more buffers (and maintain only one global list, not one list per
"   window).  Visual Studio users not used to split windows may find this
"   handy.

" Usage: {{{1
"   KEY(S)	    ACTION
"   <Space>	    show the most recently used buffer, enter Bufmru Mode
"
"   in BUFMRU MODE:
"   f  b	    reach more MRU buffers (forward/backward)
"   <Tab>  <S-Tab>  same as f and b, only with g:bufmru_splashbufs == 0
"   e  <Enter>	    accept current choice
"   !		    accept current choice (an abandoned modified buffer
"		    becomes hidden)
"   q  <Esc>	    quit the mode, go back to start buffer (forcibly)
"   y		    copy file name
"
"   The mode times out after 'timeoutlen' ms.  A key not mapped in the mode
"   (e.g. <Space>) quits the mode and executes as usual.

" Configuration: {{{1
"   :let g:bufmru_switchkey = "<Space>"
"	(checked once) Key to enter Bufmru Mode.
"
"   :let g:bufmru_confclose = 0
"	(always) Use :confirm (1) when switching buffers.  If a modified
"	buffer cannot be abandoned (only happens with 'nohidden'), this will
"	prompt you with a dialog.  Otherwise (0, default) you'll get an
"	error message.
"
"   :let g:bufmru_bnrs = []
"	(always) The internal stack of buffer numbers.  Normally, you'll
"	leave this alone, but you can manually add or remove buffer numbers
"	or initialize the list.  Don't worry about wrong numbers (though
"	duplicates aren't removed automatically).
"
"   :let g:bufmru_read_nummarks = 0
"	(checked once; only if g:bufmru_bnrs still empty) Add the number
"	mark '0..'9 buffers to g:bufmru_bnrs.
"	Note: This adds buffers to the buffer list!
"
"   :let g:bufmru_limit = 40
"	(checked when adding a bufnr) Maximum number of entries to keep in
"	the MRU list.
"
"   g:bufmru_wildmenu	(dictionary, initially not defined)
"	(always) Instance of autoload/wildmenu.vim to show buffer names in a
"	wildmenu-like list.  If not defined, bufmru tries to load the
"	autoload script.  If that fails the value becomes empty ({}) -- and
"	bufmru quite unusable.
"
"   :let g:bufmru_wilditems = "bufnr,shortpath"
"	(always) How to display entries in the "wildmenu":
"	"bufnr"		with prepended buffer number
"	"shortpath"	with pathshorten() applied to the bufname() 
"	There is no error message for wrong items.
"
" Notes: {{{1
" - "checked once": (re-)source the script to apply the change
" - "special buffer": 'buftype' not empty or 'previewwindow' set for the
"   window; not a special buffer if merely 'buflisted' is off.
"
" See Also: {{{1
" - http://vim.wikia.com/wiki/Easier_buffer_switching
" - Message-ID: <6690c6ec-7f1d-4430-9271-0511f8f874e3@e39g2000hsf.googlegroups.com>

" TODO {{{1

" End Of Comments {{{1
" }}}1

" Start Of Code

" Script Init Folklore: "{{{
if exists("loaded_bufmru")
    finish
endif
let loaded_bufmru = 1

if v:version < 700
    echomsg "bufmru: you need at least Vim 7.0"
    finish
endif

let s:sav_cpo = &cpo
set cpo&vim
"}}}

" Customization: "{{{
if !exists("g:bufmru_confclose")
    let g:bufmru_confclose = 0
endif

" mru buf is at index 0
if !exists("g:bufmru_bnrs")
    let g:bufmru_bnrs = []
endif

if !exists("g:bufmru_limit")
    let g:bufmru_limit = 40
endif

if !exists("g:bufmru_switchkey")
    let g:bufmru_switchkey = "<Space>"
endif

if !exists("g:bufmru_read_nummarks")
    let g:bufmru_read_nummarks = 0
endif

if !exists("g:bufmru_wilditems")
    let g:bufmru_wilditems = "bufnr,shortpath"
endif

"}}}

" Autocommands: "{{{
augroup bufmru
    au! BufEnter * call s:maketop(bufnr(""),1)
augroup End "}}}

" Mappings: {{{1
exec "nmap" g:bufmru_switchkey "<SID>idxz<SID>echo<SID>m_"
nmap <SID>m_f	    <SID>next<SID>echo<SID>m_
nmap <SID>m_b	    <SID>prev<SID>echo<SID>m_
nmap <SID>m_<Tab>   <SID>m_f
nmap <SID>m_<S-Tab> <SID>m_b
nmap <SID>m_<Enter> <SID>buf<SID>maybe<SID>m2
nmap <SID>m_e	    <SID>buf<SID>maybe<SID>m2
nmap <SID>m_!	    <SID>bang<SID>cleanup
nn <script> <SID>m_<Esc> <SID>cleanup:<C-U><BS>
nn <script> <SID>m_q     <SID>cleanup:<C-U><BS>
nn <script> <SID>m_      <SID>cleanup:<C-U><BS>
nmap <SID>m_y	    <SID>yank<SID>m_

nnoremap <silent> <SID>idxz	:<C-U>call<sid>idxz()<cr>
nnoremap <silent> <SID>next	:call<sid>next()<cr>
nnoremap <silent> <SID>prev	:call<sid>prev()<cr>
nnoremap <silent> <SID>buf	:call<sid>buf()<cr>
nnoremap <silent> <SID>echo	:call<sid>echo()<cr>
nnoremap <silent> <SID>yank	:call<sid>yank()<cr>
nnoremap <silent> <SID>bang	:call<sid>bang()<cr>
nnoremap <silent> <SID>cleanup	:call<sid>cleanup()<cr>

" conditional type ahead <SID>m_
nmap <expr> <SID>maybe		<sid>maybe()
" Vim bug: cannot get the type ahead directly from an <expr> map
" }}}

" Global Functions:
" add the files behind the global marks '0..'9 to the buffer list and the
" MRU list as well, and return a list of the assigned buffer numbers
func! Bufmru_Read_Nummarks() "{{{
    " call map(reverse(range(0,9)),'s:maketop(getpos("''".v:val)[0])')
    let res_bnrs = []
    for nmark in reverse(range(0,9))
	let bnr = getpos("'".nmark)[0]
	call insert(res_bnrs, bnr)
	call setbufvar(bnr, "&buflisted", 1)
	call s:maketop(bnr)
    endfor
    call s:maketop(bufnr(""))
    return res_bnrs
endfunc "}}}

" Local Functions:
func! s:maketop(bnr, ...) "{{{
    " with a:1, don't check {bnr} now, it may become valid later
    if a:0==0 && !s:isvalidbuf(a:bnr)
	return
    endif

    let idx = index(g:bufmru_bnrs, a:bnr)
    if idx >= 1
	call remove(g:bufmru_bnrs, idx)
    endif
    if idx != 0
	call insert(g:bufmru_bnrs, a:bnr)
    endif
    if g:bufmru_limit >= 1
	sil! call remove(g:bufmru_bnrs, g:bufmru_limit, -1)
    endif
endfunc "}}}

func! s:isvalidbuf(bnr) "{{{
    return buflisted(a:bnr)
	\ && getbufvar(a:bnr, '&buftype') == ""
endfunc "}}}

func! s:bnr() "{{{
    try
	let bnr = g:bufmru_bnrs[s:bidx]
	let i = 0
	while !s:isvalidbuf(bnr)
	    let s:wildmenu_update = 1
	    if i < 2
		call remove(g:bufmru_bnrs, s:bidx)
	    else
		call filter(g:bufmru_bnrs, 's:isvalidbuf(v:val)')
	    endif
	    let len = len(g:bufmru_bnrs)
	    if s:bidx >= len
		let s:bidx = len < 2 ? 0 : len-1
	    endif
	    let bnr = g:bufmru_bnrs[s:bidx]
	    let i += 1
	endwhile
    catch
	let s:wildmenu_update = 1
	let bnr = bufnr("")
	call s:maketop(bnr)
    endtry
    return bnr
endfunc "}}}

func! <sid>next() "{{{
    " let s:bidx = (s:bidx+1) % len(g:bufmru_bnrs)
    let s:bidx += 1
    let len = len(g:bufmru_bnrs)
    if s:bidx >= len
	let s:bidx = len-1
    endif
endfunc "}}}

func! <sid>prev() "{{{
    let s:bidx -= 1
    if s:bidx < 1
	" let s:bidx = len(g:bufmru_bnrs) - 1
	let s:bidx = 1
    endif
endfunc "}}}

func! <sid>idxz() "{{{
    let s:bidx = 1
    let s:switch_ok = 1
    if s:quitnormal
	let s:sav_tm = &timeoutlen
	let s:quitnormal = 0
    endif
    set timeoutlen=60000
    if !exists("g:bufmru_wildmenu")
	try
	    let g:bufmru_wildmenu = wildmenu#New()
	catch
	    let g:bufmru_wildmenu = {}
	    echomsg "Bufmru: couldn't load autoload/wildmenu.vim"
	endtry
    endif
    let s:wildmenu_update = 1
    let s:n_show = 0
endfunc "}}}

func! <sid>buf() "{{{
    let bnr = s:bnr()
    let s:switch_ok = 1
    try
	if &buftype != '' || &previewwindow
	    " special buffer
	    exec "sbuf" bnr
	elseif g:bufmru_confclose
	    exec "conf buf" bnr
	else
	    try
		exec "buf" bnr
	    catch /:E37:/
		echoerr "bufmru: No write since last change (press ! to override)"
	    endtry
	endif
	if &lazyredraw
	    redraw
	endif
    catch
	let s:switch_ok = 0
	echohl ErrorMsg
	echomsg matchstr(v:exception, ':\zs.*')
	echohl none
    endtry
endfunc "}}}

func! <sid>bang() "{{{
    let bnr = s:bnr()
    exec "buf!" bnr
    if &lazyredraw
	redraw
    endif
    let s:switch_ok = 1
endfunc "}}}

func! <sid>maybe() "{{{
    " return s:switch_ok ? "" : "<SID>m_"
    if s:switch_ok
	if &lazyredraw
	    nnoremap <SID>m2 <C-G>
	else
	    nnoremap <SID>m2 <Nop>
	endif
	" Vim bug?  <Nop> with 'lz' keeps the cursor in the cmdline and
	" times out as if there were type ahead
	call <sid>cleanup()
    else
	nmap <SID>m2 <SID>m_
    endif
    return ""
endfunc "}}}

" if buffer has no name: give it a name for the wild menu
func! s:wname(bufname) "{{{
    return a:bufname=="" ? "[unnamed]" : a:bufname
endfunc "}}}

func! <sid>echo() "{{{
    if empty(g:bufmru_wildmenu)
	return
    endif
    call s:bnr()
    if s:wildmenu_update
	let witems = split(g:bufmru_wilditems, ",")
	let wname_expr =
	    \ (index(witems, "bufnr")>=0 ? 'v:val."-".' : '')
	    \.(index(witems, "shortpath")>=0
	    \ ? 's:wname(pathshorten(bufname(v:val)))'
	    \ : 's:wname(fnamemodify(bufname(v:val),":t"))')
	    \.'.(getbufvar(v:val,"&mod") ? "[+]" : "")'
	let showlist = map(g:bufmru_bnrs[1:], wname_expr)
	call g:bufmru_wildmenu.updatewild(showlist)
	let s:wildmenu_update = 0
	let s:n_show = len(g:bufmru_bnrs) - 1
    endif
    if s:n_show >= 1
	call g:bufmru_wildmenu.showwild(s:bidx-1)
    else
	echohl WarningMsg
	echo "Only one MRU buffer"
	echohl None
    endif
endfunc "}}}

func! <sid>yank() "{{{
    let bnr = s:bnr()
    let fname = fnamemodify(bufname(bnr), ":p")
    let @@ = fname
    let cmd = "let @@ = '". fname. "'"
    call anwolib#FitEcho(cmd)
endfunc "}}}

func! <sid>cleanup() "{{{
    if !s:quitnormal
	let &timeoutlen = s:sav_tm
	let s:quitnormal = 1
    endif
endfunc "}}}

func! s:initbnrs() "{{{
    au! bufmru VimEnter
    if g:bufmru_read_nummarks
	call Bufmru_Read_Nummarks()
    endif
    if bufnr("#") >= 1
	call s:maketop(bufnr("#"))
    endif
    call s:maketop(bufnr(""))
endfunc "}}}

" Do Init: {{{1
let s:quitnormal = 1

if empty(g:bufmru_bnrs)
    if has("vim_starting")
	au! bufmru VimEnter * call s:initbnrs()
    else
	call s:initbnrs()
    endif
endif


" Cpo: {{{1
let &cpo = s:sav_cpo
unlet s:sav_cpo
"}}}
" vim:ts=8:sts=4:sw=4:noet:fdm=marker:
