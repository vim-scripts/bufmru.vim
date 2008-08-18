" bufmru - switch to most recently used buffers (simple)
" File:         bufmru.vim
" Created:      2008 Aug 18
" Last Change:  2008 Aug 18
" Rev Days:     1
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	0.1

" Usage:
"   press  <Space>  to cycle mru buffer names in the cmdline
"   press  e  or  <Enter>  to accept (within 'timeoutlen' ms)
"   any other key behaves as usual
"
" no configuration yet
"
" See Also:
"   http://vim.wikia.com/wiki/Easier_buffer_switching
"   Message-ID: <6690c6ec-7f1d-4430-9271-0511f8f874e3@e39g2000hsf.googlegroups.com>

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

augroup bufmru
    au! BufEnter * call s:maketop(bufnr(""))
augroup End

" mru buf is at index 0
if !exists("g:bufmru_bnrs")
    let g:bufmru_bnrs = []
endif
let s:bnr = 1
let s:bidx = 0 

func! s:maketop(bnr)
    " do not add some kind of buffers:
    if &buftype != ""
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

func! s:bnr()
    try
	let bnr = g:bufmru_bnrs[s:bidx]
	if !bufexists(bnr)
	    call remove(g:bufmru_bnrs, s:bidx)
	    let bnr = s:bnr()
	endif
    catch
	let bnr = bufnr("")
    endtry
    return bnr
endfunc

func! <sid>next()
    let s:bidx = (s:bidx+1) % len(g:bufmru_bnrs)
endfunc

func! <sid>idxz()
    let s:bidx = 1
endfunc

func! <sid>buf()
    exec "b" s:bnr()
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

nmap <Space>		<sid>idxz<sid>echo<sid>m_
nmap <sid>m_<Space>	<sid>next<sid>echo<sid>m_
nmap <sid>m_<Enter>	<sid>buf
nmap <sid>m_e		<sid>buf
nn   <sid>m_		:<C-U><BS>

nnoremap <silent> <SID>idxz :call<sid>idxz()<cr>
nnoremap <silent> <SID>next :call<sid>next()<cr>
nnoremap <silent> <SID>buf  :call<sid>buf()<cr>
nnoremap <silent> <SID>echo :call<sid>echo()<cr>

let &cpo = s:sav_cpo
unlet s:sav_cpo

" vim:ts=8:sts=4:sw=4:noet
