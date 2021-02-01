" Vim global plugin for markers and stuff
" Last Change:	2021 Jan 31
" Maintainer:	fbtd
" License:		This file is placed in the public domain.
"
" TODO: store file name using fnameescape()
" TODO: add support to files not in blist
" FIXME: handle preview windows

if exists("g:loaded_markerpath")
    finish
endif
let g:loaded_markerpath = 1

let s:save_cpo = &cpo
set cpo&vim

let s:uppers = "QWERTZUIOPASDFGHJKLYXCVBNM"

" Save markers to global variables g:Marker_A ... _Z
function! s:MarkersToGlobals()
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

"TODO arg contains b, display buffers, a, display args, m, display local marks..
"TODO add some text of the line
function! DisplayMarks()
    let buffer_infos = map(getbufinfo(), function('s:AddFilenameToBufinfo'))
    call sort(buffer_infos, function('s:SortBufinfosByFilename'))
    let filenames_markers_dict = s:GetDictOfMarkersPerFile()
    echohl Title
    echo('MARKS   b a t filename')
    echohl None
"   for k in keys(filenames_markers_dict)
"       echom k . " " . filenames_markers_dict[k][0]
"   endfor
    for buf in buffer_infos
        if has_key(filenames_markers_dict, buf['filename'])
            echohl CursorLine
            let markers = join(filenames_markers_dict[buf['filename']], "")
        else
            let markers = ''
        endif
        echo printf('%5s %3d %d %d %s', markers, buf['bufnr'], 1, 1, buf['filename'])
        echohl None
    endfor
"   echom buffer_infos[0]['filename']
endfunction

autocmd SessionLoadPost * call <SID>GlobalsToMarkers()

if !hasmapto('<Plug>MarkersToGlobals')
  nmap <unique> <Leader>a  <Plug>MarkerpathMarkersToGlobals
endif
nnoremap <unique> <script> <Plug>MarkerpathMarkersToGlobals  <SID>MarkersToGlobals
nnoremap <leader>a :call <SID>MarkersToGlobals()<CR>

if !exists(":Mk")
    command Mk :call <SID>MarkersToGlobals()<bar>:mksession!
endif


let &cpo = s:save_cpo
unlet s:save_cpo
