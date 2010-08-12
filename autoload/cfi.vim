" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Load Once {{{
if exists('s:loaded') && s:loaded
    finish
endif
let s:loaded = 1
" }}}
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}



let s:finder = {}



function! cfi#load() "{{{
    runtime! plugin/cfi.vim
endfunction "}}}

function! cfi#get_func_name(...) "{{{
    let filetype = a:0 ? a:1 : &l:filetype
    let NONE = ""

    if !has_key(s:finder, filetype)
        " TODO
        " If there is [[ keymapping, use it.
        " (In C (especially C++), it had better use [m keymapping)
        return NONE
    endif

    if !s:finder[filetype]._mixed
        call extend(s:finder[filetype], deepcopy(s:base_finder), 'keep')
        let s:finder[filetype]._mixed = 1
    endif

    if !has_key(s:finder[filetype], 'find')
        return NONE
    endif

    let val = s:finder[filetype].find()
    return type(val) == type("") ? val : NONE
endfunction "}}}

function! cfi#create_finder(filetype) "{{{
    if !has_key(s:finder, a:filetype)
        let s:finder[a:filetype] = {'_mixed': 0, 'is_ready': 0, 'phase': 0}
    endif
    return s:finder[a:filetype]
endfunction "}}}

function! cfi#has_supported_for(filetype) "{{{
    return has_key(s:finder, a:filetype)
endfunction "}}}



let s:base_finder = {}

function! s:base_finder.find() "{{{
    " TODO Cache while being in function.
    let NONE = 0
    let orig_pos = getpos('.')
    let [orig_lnum, orig_col] = [orig_pos[1], orig_pos[2]]
    let match = NONE
    let normal_is_used = 0

    if !s:has_base_finder_find_must_methods(self)
        return NONE
    endif

    try
        let self.phase = 1
        for method in ['find_begin', 'find_begin_normal']
            if has_key(self, method)
                if method ==# 'find_begin_normal'
                    let normal_is_used = 1
                endif
                if self[method]() == 0
                    return NONE
                endif
                break
            endif
        endfor
        if self.is_ready
            let match = self.get_func_name()
        endif

        let [begin_lnum, begin_col] = [line('.'), col('.')]

        let self.phase = 2
        for method in ['find_end', 'find_end_normal']
            if has_key(self, method)
                if method ==# 'find_end_normal'
                    let normal_is_used = 1
                endif
                if self[method]() == 0
                    return NONE
                endif
                break
            endif
        endfor
        if self.is_ready && match is NONE
            let match = self.get_func_name()
        endif

        if match is NONE
            return NONE
        endif

        " function's begin pos -> {original pos} -> function's end pos
        let in_function =
        \   self.pos_is_less_than([begin_lnum, begin_col], [orig_lnum, orig_col])
        \   && self.pos_is_less_than([orig_lnum, orig_col], [line('.'), col('.')])
        if !in_function
            return NONE
        endif

        return match
    finally
        " Vim's bug: http://groups.google.com/group/vim_dev/browse_thread/thread/af729cf53e7d7abe
        if normal_is_used
            if col('.') != orig_col
                execute 'normal!' abs(col('.') - orig_col) . (col('.') > orig_col ? 'h' : 'l')
            endif
        endif

        let self.is_ready = 0
        let self.phase = 0

        call setpos('.', orig_pos)
    endtry
endfunction "}}}

function! s:has_base_finder_find_must_methods(this) "{{{
    if !has_key(a:this, 'get_func_name')
        return 0
    endif
    if !has_key(a:this, 'find_begin') && !has_key(a:this, 'find_begin_normal')
        return 0
    endif
    if !has_key(a:this, 'find_end') && !has_key(a:this, 'find_end_normal')
        return 0
    endif
    return 1
endfunction "}}}

function! s:base_finder.pos_is_less_than(pos1, pos2) "{{{
    let [lnum1, col1] = a:pos1
    let [lnum2, col2] = a:pos2
    return
    \   lnum1 < lnum2
    \   || (lnum1 == lnum2
    \       && col1 < col2)
endfunction "}}}


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
