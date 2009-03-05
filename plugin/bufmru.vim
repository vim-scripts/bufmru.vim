" bufmru - switch to most recently used buffers
" File:         bufmru.vim
" Vimscript:	#2346
" Created:      2008 Aug 18
" Last Change:  2009 Mar 05
" Rev Days:     21
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	1.0
" Credits:	Anton Sharonov (g:bufmru_splashbufs)
" License:	Vim license
 
" Comments

" Description: {{{1
"   Switch between MRU buffers from the current session. Like CTRL-^, but
"   reach more buffers (and maintain only one global list, not one list per
"   window).  Visual Studio users not used to split windows may find this
"   handy.

" Usage: {{{1
"   Usage highly depends on g:bufmru_splashbufs, see Configuration.
"
"   KEY(S)	    ACTION
"   <Space>	    switch-to or show the most recently used buffer, enter
"   		    Bufmru Mode
"
"   in BUFMRU MODE:
"   f  b	    reach more MRU buffers (forward/backward)
"   e  <Enter>	    accept current choice
"   !		    accept current choice (an abandoned modified buffer
"		    becomes hidden)
"   q  <Esc>	    quit the mode, go back to start buffer (forcibly)
"   y		    copy file name
"
"   The mode times out after 'timeoutlen' ms.  A key not mapped in the mode
"   (e.g. <Space>) quits the mode and executes as usual.

" Configuration: {{{1
"   :let g:bufmru_splashbufs = 0
"	(checked once) If 1, switch buffers instantly like with CTRL-^.  If
"	0 (default), only show MRU buffer names in the command-line and
"	switch to a buffer when you press e or <Enter>.
"
"   :let g:bufmru_switchkey = "<Space>"
"	(checked once) Key to enter Bufmru Mode.
"
"   :let g:bufmru_confclose = 0
"	(always) Use :confirm (1) when abandoning a modified buffer.
"	Otherwise (0, default) you'll get an error message, unless 'hidden'
"	is set.
"
"   :let g:bufmru_bnrs = []
"	(always) The internal stack of buffer numbers.  Normally, you'll
"	leave this alone, but you can manually add or remove buffer numbers
"	or initialize the list.  Don't worry about wrong numbers.
"
"   :let g:bufmru_read_nummarks = 0
"	(checked once; only if g:bufmru_bnrs still empty) Add the number
"	mark '0..'9 buffers to g:bufmru_bnrs.
"	Note: This adds buffers to the buffer list!
"
"   :let g:bufmru_limit = 40
"	(often) Maximum number of entries to keep in the MRU list.
"
" Notes: {{{1
" - "checked once": (re-)source the script to apply the change
" - "special buffer": 'buftype' not empty or 'previewwindow' set for the
"   window.  Not a special buffer if 'buflisted' is off.
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
if !exists("g:bufmru_splashbufs")
    let g:bufmru_splashbufs = 0
endif
let s:splash_const = g:bufmru_splashbufs

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
"}}}
" Autocommands: "{{{
augroup bufmru
    if g:bufmru_splashbufs
	au! BufEnter * if !s:noautocmd| call s:maketop(bufnr(""),1)| endif
    else
	au! BufEnter * call s:maketop(bufnr(""),1)
    endif
augroup End "}}}
" Mappings: {{{1
if g:bufmru_splashbufs
    exec "nmap" g:bufmru_switchkey "<SID>idxz<SID>buf<SID>m_"
    nmap <SID>m_f	<SID>next<SID>buf<SID>m_
    nmap <SID>m_b	<SID>prev<SID>buf<SID>m_
    nmap <SID>m_!	<SID>bang<SID>m_
    nmap <SID>m_<Enter>	<SID>raccept
    nmap <SID>m_e	<SID>raccept
    nmap <SID>m_<Esc>	<SID>reset
    nmap <SID>m_q	<SID>reset
    nmap <SID>m_	<SID>raccept
else
    exec "nmap" g:bufmru_switchkey "<SID>idxz<SID>echo<SID>m_"
    nmap <SID>m_f	<SID>next<SID>echo<SID>m_
    nmap <SID>m_b	<SID>prev<SID>echo<SID>m_
    nmap <SID>m_<Enter>	<SID>buf<SID>maybe
    nmap <SID>m_e	<SID>buf<SID>maybe
    nmap <SID>m_!	<SID>bang
    nn	 <SID>m_<Esc>	:<C-U><BS>
    nn	 <SID>m_q	:<C-U><BS>
    nn	 <SID>m_	:<C-U><BS>
endif
nmap <SID>m_y	<SID>yank<SID>m_

nnoremap <silent> <SID>idxz	:<C-U>call<sid>idxz()<cr>
nnoremap <silent> <SID>next	:call<sid>next()<cr>
nnoremap <silent> <SID>prev   	:call<sid>prev()<cr>
nnoremap <silent> <SID>buf    	:call<sid>buf()<cr>
nnoremap <silent> <SID>echo   	:call<sid>echo()<cr>
nnoremap <silent> <SID>raccept 	:call<sid>reset(1)<cr>
nnoremap <silent> <SID>reset 	:call<sid>reset(0)<cr>
nnoremap <silent> <SID>yank   	:call<sid>yank()<cr>
nnoremap <silent> <SID>bang	:call<sid>bang()<cr>

" conditional type ahead <SID>m_
nmap	    <SID>maybe		<SID>m1<SID>m2
nmap <expr> <SID>m1		<sid>maybe()
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
    sil! call remove(g:bufmru_bnrs, g:bufmru_limit, -1)
endfunc "}}}

func! s:isvalidbuf(bnr) "{{{
    return a:bnr >= 1
	\ && bufexists(a:bnr)
	\ && getbufvar(a:bnr, '&buftype') == ""
	\ && buflisted(a:bnr)
endfunc "}}}

func! s:bnr() "{{{
    try
	let bnr = g:bufmru_bnrs[s:bidx]
	let i = 0
	while !s:isvalidbuf(bnr)
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
	let bnr = bufnr("")
	call s:maketop(bnr)
    endtry
    return bnr
endfunc "}}}

func! <sid>next() "{{{
    " let s:bidx = (s:bidx+1) % len(g:bufmru_bnrs)
    if s:splash_const && !s:switch_ok
	return
    endif
    let s:bidx += 1
    let len = len(g:bufmru_bnrs)
    if s:bidx >= len
	let s:bidx = len-1
	if s:splash_const
	    echohl WarningMsg
	    echo "No older MRU buffers"
	    echohl None
	else
	    let s:cyclewarn = 1
	endif
    endif
endfunc "}}}

func! <sid>prev() "{{{
    if s:splash_const && !s:switch_ok
	return
    endif
    let s:bidx -= 1
    if s:bidx < 1
	" let s:bidx = len(g:bufmru_bnrs) - 1
	let s:bidx = 1
	if s:splash_const
	    echohl WarningMsg
	    echo "At start buffer"
	    echohl None
	else
	    let s:cyclewarn = 1
	endif
    endif
endfunc "}}}

func! <sid>idxz() "{{{
    let s:bidx = 1
    let s:noautocmd = s:splash_const
    let s:bstart = bufnr("")
    let s:switch_ok = 1
    let s:cyclewarn = 0
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
    let s:switch_ok = 1
endfunc "}}}

func! <sid>maybe() "{{{
    " return s:switch_ok ? "" : "<SID>m_"
    if s:switch_ok
	nmap <SID>m2 <Nop>
    else
	nmap <SID>m2 <SID>m_
    endif
    return ""
endfunc "}}}

func! <sid>echo() " {{{
    " redraw
    let bnr = s:bnr()
    if len(g:bufmru_bnrs) < 2
	return
    endif
    let bmod = getbufvar(bnr, "&modified")
    let bufnamewidth = (&columns-12) - (strlen(bnr)+1 + (bmod ? 4 : 0))
    let bufname = bufname(bnr)
    if s:cyclewarn| echohl WarningMsg| endif
    if bufname != ""
	echo bnr s:truncname(bufname, bufnamewidth)
    else
	echo bnr "[unnamed]"
    endif
    if s:cyclewarn| echohl None| endif
    if bmod
	echohl WarningMsg| echon " [+]"| echohl None
    endif
    let s:cyclewarn = 0
endfunc "}}}

func! <sid>yank() "{{{
    let bnr = s:bnr()
    let fname = fnamemodify(bufname(bnr), ":p")
    let @@ = fname
    let cmd = "let @@ = '". fname. "'"
    echo s:truncstr(cmd, &columns-12)
endfunc "}}}

func! <sid>reset(accept) "{{{
    call s:maketop(bufnr(""))
    let s:noautocmd = 0
    if !a:accept
	" try to go back, no matter if this doesn't work:
	exec "sil! buf!" s:bstart
    endif
    if !s:switch_ok
	" <Enter>, e just fail - remove the error message suggesting the
	" overriding
	exec "norm! :\<C-U>"
    endif
endfunc "}}}

func! s:truncname(bufname, maxlen) "{{{
    if strlen(a:bufname) <= a:maxlen
	return a:bufname
    endif
    let bufname = a:bufname
    let pat = '[^\\/]\zs[^\\/:]\+[\\/]\@='
    while 1
	let blen = strlen(bufname)
	let shorter = substitute(bufname, pat,'','')
	if strlen(shorter) == blen || blen <= a:maxlen
	    break
	endif
	let bufname = shorter
    endwhile
    return s:truncstr(bufname, a:maxlen)
endfunc "}}}

func! s:truncstr(str, maxlen) "{{{
    let len = strlen(a:str)
    if len > a:maxlen
	let amountl = (a:maxlen / 2) - 2
	let amountr = a:maxlen - amountl - 3
	let lpart = strpart(a:str, 0, amountl)
	let rpart = strpart(a:str, len-amountr)
	return strpart(lpart. '...'. rpart, 0, a:maxlen)
    else
	return a:str
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
let s:noautocmd = 0

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
