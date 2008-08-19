" bufmru - switch to most recently used buffers (simple)
" File:         bufmru.vim
" Vimscript:	#2346
" Created:      2008 Aug 18
" Last Change:  2008 Aug 19
" Rev Days:     2
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	0.2

" Usage:
"   Press  <Space>  or  b  (back) to cycle mru buffer names in the cmdline.
"   Press  e  or  <Enter>  to accept (within 'timeoutlen' ms).
"   Other keys behave as usual,  <Esc>  and  q  just quit (not executing).
"
" Configuration:
"   :let g:bufmru_switchkey = "<Space>"
"	(checked once) Key to enter bufmru mode and to cycle buffer names.
"
"   :let g:bufmru_confclose = 1
"	(always) Use :confirm (1, default) or :hide (0) when abandoning a
"	modified buffer.  Only makes a difference with 'nohidden'.  Also not
"	an issue in a window with a special buffer, it is split first.
"
"   :let g:bufmru_bnrs (list)
"	(always) Actually the internal stack of buffer numbers.  But you can
"	manually add or remove buffer numbers or initialize the list.
"
" Notes:
" - "special buffer": 'buftype' not empty or 'previewwindow' set.
"
" See Also:
" - http://vim.wikia.com/wiki/Easier_buffer_switching
" - Message-ID: <6690c6ec-7f1d-4430-9271-0511f8f874e3@e39g2000hsf.googlegroups.com>

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

if !exists("g:bufmru_confclose")
    let g:bufmru_confclose = 1
endif

" mru buf is at index 0
if !exists("g:bufmru_bnrs")
    let g:bufmru_bnrs = []
endif

if !exists("g:bufmru_switchkey")
    let g:bufmru_switchkey = "<Space>"
endif

augroup bufmru
    au! BufEnter * call s:maketop(bufnr(""))
augroup End

func! s:maketop(bnr)
    if !s:isvalidbuf(a:bnr)
	return
    endif

    let idx = index(g:bufmru_bnrs, a:bnr)
    if idx >= 1
	call remove(g:bufmru_bnrs, idx)
    endif
    if idx != 0
	call insert(g:bufmru_bnrs, a:bnr)
    endif
endfunc

func! s:isvalidbuf(bnr)
    return a:bnr >= 1
	\ && bufexists(a:bnr)
	\ && getbufvar(a:bnr, '&buftype') == ""
endfunc

func! s:bnr()
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
		let s:bidx = len < 2 ? 0 : 1
	    endif
	    let bnr = g:bufmru_bnrs[s:bidx]
	    let i += 1
	endwhile
    catch
	let bnr = bufnr("")
	call s:maketop(bnr)
    endtry
    return bnr
endfunc

func! <sid>next()
    let s:bidx = (s:bidx+1) % len(g:bufmru_bnrs)
endfunc

func! <sid>prev()
    let s:bidx -= 1
    if s:bidx < 0
	let s:bidx = len(g:bufmru_bnrs) - 1
    endif
endfunc

func! <sid>idxz()
    let s:bidx = 1
endfunc

func! <sid>buf()
    if &buftype != '' || &previewwindow
	exec "sbuf" s:bnr()
    else
	let hide = !g:bufmru_confclose
	exec ["conf","hide"][hide && &mod] "buf" s:bnr()
    endif
endfunc

func! <sid>echo()
    redraw
    let bnr = s:bnr()
    let bufname = bufname(bnr)
    if bufname != ""
	echo bnr bufname
    else
	echo bnr "[unnamed]"
    endif
endfunc

let s:bnr = 1
let s:bidx = 0 

if empty(g:bufmru_bnrs)
    if bufnr("#") >= 1
	call s:maketop(bufnr("#"))
    endif
    call s:maketop(bufnr(""))
endif

exec "nmap" g:bufmru_switchkey "<sid>idxz<sid>echo<sid>m_"
exec "nmap <sid>m_".g:bufmru_switchkey "<sid>next<sid>echo<sid>m_"
nmap <sid>m_b		<sid>prev<sid>echo<sid>m_
nmap <sid>m_<Enter>	<sid>buf
nmap <sid>m_e		<sid>buf
nn   <sid>m_<Esc>	:<C-U><BS>
nn   <sid>m_q		:<C-U><BS>
nn   <sid>m_		:<C-U><BS>

nnoremap <silent> <SID>idxz :call<sid>idxz()<cr>
nnoremap <silent> <SID>next :call<sid>next()<cr>
nnoremap <silent> <SID>prev :call<sid>prev()<cr>
nnoremap <silent> <SID>buf  :call<sid>buf()<cr>
nnoremap <silent> <SID>echo :call<sid>echo()<cr>

let &cpo = s:sav_cpo
unlet s:sav_cpo

" vim:ts=8:sts=4:sw=4:noet
