" function library -- some small general unrelated homeless functions ...
" File:         anwolib.vim
" Created:      2007 Dec 07
" Last Change:  2009 May 10
" Rev Days:     14
" Author:	Andy Wokula <anwoku@yahoo.de>
" License:	Vim license

" Other libs to consider: {{{
"   genutils	Vimscript #197 (Hari Krishna Dara)
"   cecutil	Vimscript #1066 (DrChip)
"   tlib	Vimscript #1863 (Thomas Link)
"   TOVL	Vimscript #1963 (Marc Weber)
"		http://github.com/MarcWeber/theonevimlib
" }}}

" like extend({baselist}, {append}), but only insert missing items
" Notes:
" - the {append} list is changed, use copy() to protect it
" - duplicates from {append} are not removed
func! anwolib#ExtendUniq(baselist, append, ...) "{{{
    " Changed: 2009 Mar 04
    " {baselist}    (list)
    " {append}	    (list)
    " a:1	    index for insertion of {append}
    if a:0 == 0
	return extend(a:baselist, filter(a:append, 'index(a:baselist,v:val)==-1'))
    else
	return extend(a:baselist, filter(a:append, 'index(a:baselist,v:val)==-1'), a:1)
    endif
    return a:baselist
endfunc "}}}

" (in place) remove duplicates from a list
func! anwolib#RemoveDups(list) "{{{
    " Changed: 2009 Mar 05
    let len = len(a:list)
    let idx = len-1
    while idx >= 1
	if index(a:list, a:list[idx]) < idx
	    call remove(a:list, idx)
	endif
	let idx -= 1
    endwhile
    return a:list
endfunc "}}}

" original PairList from 10-05-2007
" [1,2,3,4], [5,6,7] -> [[1,5], [2,6], [3,7]]
func! anwolib#PairList(list1, list2) "{{{
    " Changed: 2007 Dec 07
    try
	let idx = 0
	let result = []
	while 1
	    call add(result, [a:list1[idx], a:list2[idx]])
	    let idx += 1
	endwhile
    catch /:E684:/
	" list index out of range - ignore
    endtry
    return result
endfunc "}}}

" split a string at the first occurrence of whitespace (after non-
" whitespace); return a list with two elements
func! anwolib#Split1(str) "{{{
    " Changed: 2009 Mar 04
    let str = substitute(a:str, '^\s*\|\s*$', '', 'g')
    let spos = match(str, '\S\zs\s\+\S')
    if spos > 0
	let srhs = match(str, '\S', spos)
	return [str[: spos-1], str[srhs :]]
    else
	return [str, ""]
    endif
endfunc "}}}

" expand all hardtabs in {line} with given {tabstop} setting
func! anwolib#ExpandTabs(line, ...) "{{{
    " Changed: 2009 Feb 02
    " {line} - (string)
    " a:1 {tabstop} - (number) defaults to &tabstop
    let ts = a:0 >= 1 ? a:1 : &tabstop
    let splitline = split(a:line,'\t\t\@!\zs\|[^\t]\t\@=\zs')
    let nparts = len(splitline)
    let modts = 0     " modts = string-index (modulo 'tabstop')
    let partidx = 0
    while partidx < nparts
        let part = splitline[partidx]
        if part[0] == "\t"
            let nspc = ts - modts % ts
            let modts += nspc
	    let splitline[partidx] = repeat(" ", nspc + ts * (strlen(part)-1))
        else
            let modts += strlen(part)
        endif
        let partidx += 1
    endwhile
    return join(splitline, "")
endfunc "}}}
func! anwolib#ExpandTabs_Mbyte(line, ...) "{{{
    " Changed: 2009 Feb 02
    " {line} - (string)
    " a:1 {tabstop} - (number) defaults to &tabstop
    let ts = a:0 >= 1 ? a:1 : &tabstop
    let splitline = split(a:line,'\t\t\@!\zs\|[^\t]\t\@=\zs')
    let nparts = len(splitline)
    let modts = 0     " modts = string-index (modulo 'tabstop')
    let partidx = 0
    while partidx < nparts
        let part = splitline[partidx]
        if part[0] == "\t"
            let nspc = ts - modts % ts
            let modts += nspc
	    let splitline[partidx] = repeat(" ", nspc + ts * (strlen(part)-1))
        else
            let modts += strlen(substitute(part, ".", "x", "g"))
        endif
        let partidx += 1
    endwhile
    return join(splitline, "")
endfunc "}}}
"" Garbage: {{{
"" let fulletab = repeat(" ", ts)
"" let spaces = repeat(" ", nspc)
"" let nresttabs = strlen(part) - 1
"" while nresttabs > 0
""     let spaces .= fulletab
""     let nresttabs -= 1
"" endwhile
"" let splitline[partidx] = spaces
"}}}

func! anwolib#Rot13(str) "{{{
    " Changed: 2007 May 22
    let from = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    let to =   "NOPQRSTUVWXYZABCDEFGHIJKLMnopqrstuvwxyzabcdefghijklm"
    return tr(a:str, from, to)
endfunc "}}}

func! anwolib#CmdlineWidth() "{{{
    let showcmd_off = &showcmd ? 11 : 0
    let laststatus_off = !&ruler || &laststatus==2 ? 0
	\ : &laststatus==0 ? 19 : winnr('$')==1 ? 19 : 0
    return &columns - showcmd_off - laststatus_off - 1
    " rule of thumb, former 17 for the ruler wasn't enough
    " has('cmdline_info') && has('statusline')
    " default 'rulerformat' assumed
    " should be merged with tlib#notify#*()
endfunc "}}}

func! anwolib#FitEcho(str) "{{{
    echo anwolib#TruncStr(a:str, anwolib#CmdlineWidth())
endfunc "}}}

" if {str} is longer than {maxlen}, insert "..." in the middle; return the
" modified string
func! anwolib#TruncStr(str, maxlen) "{{{
    " Changed: 2009 Mar 03
    let len = strlen(a:str)
    if len <= a:maxlen
	return a:str
    endif
    if a:maxlen >= 4
	if a:maxlen >= 7
	    let dots = "..."
	    let amountl = (a:maxlen / 2) - 2
	    " it's good to see more of the end of the string
	else
	    let dots = ".."
	    let amountl = (a:maxlen / 2) - 1
	endif
	let amountr = a:maxlen - amountl - strlen(dots)
	let lpart = strpart(a:str, 0, amountl)
	let rpart = strpart(a:str, len-amountr)
	return strpart(lpart. dots. rpart, 0, a:maxlen)
    elseif a:maxlen <= 0
	return ""
    else
	return strpart(a:str, 0, a:maxlen)
    endif
endfunc "}}}

" like TruncStr(), but do pathshorten() first
func! anwolib#TruncFilename(filename, maxlen) "{{{
    " Changed: 2009 Mar 07
    if strlen(a:filename) <= a:maxlen
	return a:filename
    endif
    let filename = a:filename
    let pat = '[^\\/]\zs[^\\/:]\+[\\/]\@='
    while 1
	let blen = strlen(filename)
	let shorter = substitute(filename, pat,'','')
	if strlen(shorter) == blen || blen <= a:maxlen
	    break
	endif
	let filename = shorter
    endwhile
    return anwolib#TruncStr(filename, a:maxlen)
endfunc "}}}

func! anwolib#MagicEscape(pat, ...) "{{{
    " Changed: 2009 Mar 03
    " a:1   fbc, extra search forward (/) or backward (?) character to be
    " 	    escaped (default '/')
    let fbc = a:0>=1 ? a:1 : '/'
    return escape(a:pat, fbc. '\.*$^~[')
endfunc "}}}

" vim:set fdm=marker:
