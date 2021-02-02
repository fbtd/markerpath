" Vim global plugin for markers and stuff
" Last Change:	2021 Feb 2
" Maintainer:	fbtd
" License:		This file is placed in the public domain.
"
" TODO: store file name using fnameescape()
" TODO: add support to files not in blist
" FIXME: handle preview windows
"
" Public functions:
" MP_MarkersToGlobals()     to save Markers ino global vars
" MP_EchomAll()             to show a list of open files w/ markers

if exists("g:loaded_markerpath")
    finish
endif
let g:loaded_markerpath = 1

let s:save_cpo = &cpo
set cpo&vim

let s:uppers = "QWERTZUIOPASDFGHJKLYXCVBNM"

" Save markers to global variables g:Marker_A ... _Z
function! MP_MarkersToGlobals()
    let i = 0
    while i < strlen(s:uppers)
        let pos = getpos("'" . s:uppers[i])
        if pos[0]
            let pos_string = join(pos)
            execute 'let g:Marker_' . s:uppers[i] . ' =  pos_string'
        endif
        let i = i + 1
    endwhile
endfunction

" Set markers from Global variables g:Marker_A ... _Z
function! s:GlobalsToMarkers()
    let i = 0
    while i < strlen(s:uppers)
        let v_name = 'g:Marker_' . s:uppers[i]
        let m_name = "'" . s:uppers[i]
        if exists(v_name)
            execute 'let pos_list = split(' . v_name . ')'
            call setpos(m_name, pos_list)
        endif
        let i = i + 1
    endwhile
endfunction

function! s:AddFilenameToBufinfo(index, bufinfo)
    let a:bufinfo['filename'] = bufname(a:bufinfo['bufnr'])
    return a:bufinfo
endfunction

function! s:SortBufinfosByFilename(b1, b2)
    if a:b1['filename'] < a:b2['filename']
        return -1
    endif
    return a:b1['filename'] > a:b2['filename']
endfunction

" Return a dict. Keys = filenames, values = List of MARKS set in key's file
function! s:GetDictOfMarkersPerFile()
    let d = {}
    let i = 0
    while i < strlen(s:uppers)
        let pos = getpos("'" . s:uppers[i])
        if pos[0]
            let filename = bufname(pos[0])
            if !has_key(d, filename)
                let d[filename] = []
            endif
            call add(d[filename], s:uppers[i])
        endif
        let i = i + 1
    endwhile
    return d
endfunction

" Return a dict. Keys = filenames, values = List of tabs where filename is displayed
function! s:GetDictOfTabsPerFile()
    let d = {}
    let i = 1
    while i <= tabpagenr('$')
        for buf in tabpagebuflist(i)
            let filename = bufname(buf)
            if !has_key(d, filename)
                let d[filename] = []
            endif
            call add(d[filename], i)
        endfor
        let i = i + 1
    endwhile
    return d
endfunction

" Return a dict. Keys = filenames, values = List of tabs where filename is displayed
function! s:GetDictOfArgPerFile()
    let d = {}
    let i = 0
    while i <= argc()
        let d[argv(i)] =  i
    let i = i + 1
    endwhile
    return d
endfunction

function! s:Goto(somewhere)
    if a:somewhere =~ '^[a-zA-Z]$'
        execute "normal! `" . toupper(a:somewhere)
    elseif a:somewhere =~ '[0-9]\+b'
        execute a:somewhere
    elseif a:somewhere =~ '[0-9]\+'
        execute 'argument ' . (a:somewhere + 1)
    endif
endfunction

"TODO arg contains b, display buffers, a, display args, m, display local marks..
"TODO add some text of the line
function! MP_EchomAll()
    let buffer_infos = map(getbufinfo(), function('s:AddFilenameToBufinfo'))
    call sort(buffer_infos, function('s:SortBufinfosByFilename'))
    let filenames_markers_dict = s:GetDictOfMarkersPerFile()
    let filenames_tabs_dict = s:GetDictOfTabsPerFile()
    let filenames_arg_dict = s:GetDictOfArgPerFile()
    echohl Title
    echo('MARKS   b a  t filename')
    echohl None
"   let i = 1
    for buf in buffer_infos
"       if i%2 | echohl None | else | echohl CursorLine | endif
"       let i = i+1
        let markers = ''
        if has_key(filenames_markers_dict, buf['filename'])
            let markers = join(filenames_markers_dict[buf['filename']], "")
        endif
        let tabs = ''
        if has_key(filenames_tabs_dict, buf['filename'])
            let tabs = join(filenames_tabs_dict[buf['filename']], "")
        endif
        let arg = ''
        if has_key(filenames_arg_dict, buf['filename'])
            let arg = filenames_arg_dict[buf['filename']]
        endif
        if bufnr() == buf['bufnr'] | echohl CursorLine | endif
        echo printf('%5s %3s %1s %2s %s', markers, buf['bufnr'], arg, tabs, buf['filename'])
        echohl None
    endfor
    call s:Goto(input('going somewhere?'))
endfunction

autocmd SessionLoadPost * call <SID>GlobalsToMarkers()

let &cpo = s:save_cpo
unlet s:save_cpo
