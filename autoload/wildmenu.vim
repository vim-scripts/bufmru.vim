" a wildmenu object for the cmdline area
" File:         wildmenu.vim
" Created:      2009 Mar 02
" Last Change:  2009 Apr 23
" Rev Days:     7
" Author:	Andy Wokula <anwoku@yahoo.de>
" Version:	0.2
" License:	Vim license

" TODO

" Usage:
"   :let bt = wildmenu#New()
"
"   " create/update the list:
"   :call bt.updatewild( ['Lorem', 'ipsum', 'dolor', 'sit'] )
"
"   " show list with selected item at index
"   :call bt.showwild( 0 )
"   :call bt.showwild( 3 )
"
"   " error cases:
"   :call bt.showwild( -1 )
"   :call bt.showwild( 99 )
"
"   :call bt.updatewild( ['foo'] )
"   :call bt.updatewild( ['foo','bar'] )
"   :call bt.showwild( -1 )
"   :call bt.showwild( 99 )

let s:wildmenu = {}

func! wildmenu#New() "{{{
    let btobj = deepcopy(s:wildmenu)
    let btobj.hlgroup = "WildMenu"
    let btobj.showlist = []
    return btobj
endfunc "}}}

" example list of buffer numbers:
func! wildmenu#GetBnrList() "{{{
    let bnrlist = range(1, bufnr("$"))
    call filter(bnrlist, 'buflisted(v:val) && getbufvar(v:val, "&modifiable")')
    return bnrlist
endfunc "}}}

func! s:wildmenu.updatewild(showlist) "{{{
    let self.showlist = a:showlist
    let self.lastindex = -1
    let len = len(self.showlist)
    " indx into showlist
    let self.indx = [0]
    let width = anwolib#CmdlineWidth()
    let wildstrlen = -2
    let idx = 0
    while idx < len
	let bnamelen = 2 + strlen(self.showlist[idx])
	if wildstrlen + bnamelen > width-2
	    call add(self.indx, idx)
	    let wildstrlen = bnamelen
	else
	    let wildstrlen += bnamelen
	endif
	let idx += 1
    endwhile
    call add(self.indx, len)
endfunc "}}}
func! s:wildmenu.showwild( index ) "{{{
    let index = a:index < 0 ? 0 : a:index
    if index == self.lastindex
	return
    endif
    let len = len(self.showlist)
    let indxlen = len(self.indx)
    let lnum = 0    " number of wildmode line
    while lnum+1 < indxlen && self.indx[lnum+1] <= index 
	let lnum += 1
    endwhile
    if lnum+1 == indxlen
	let lnum -= 1
	let index = self.indx[lnum+1] - 1
    endif
    let hlcmd = "echohl ". self.hlgroup
    let wildstr = lnum==0 ? "" : "< "
    let idx = self.indx[lnum]
    let beyidx = self.indx[lnum+1]
    if idx+1 == beyidx
	let width = anwolib#CmdlineWidth()
	let entry = self.showlist[idx]
	let slen = strlen(entry)
	if lnum==0 && slen+2 <= width || slen+4 <= width
	    echo wildstr
	    exec hlcmd| echon entry| echohl None
	    if beyidx < len
		echon " >"
	    endif
	else
	    exec hlcmd
	    echo anwolib#TruncStr(entry, width)
	    echohl None
	endif
    else
	let spaces = ""
	while idx < beyidx
	    if idx == index
		echo wildstr. spaces
		exec hlcmd| echon self.showlist[idx]| echohl None
		let wildstr = ""
	    else
		let wildstr .= spaces. self.showlist[idx]
	    endif
	    let spaces = "  "
	    let idx += 1
	endwhile
	echon wildstr
	if idx < len
	    echon " >"
	endif
    endif
    let self.lastindex = index
endfunc "}}}

" vim:set fdm=marker:
