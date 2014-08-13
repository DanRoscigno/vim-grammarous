let s:save_cpo = &cpo
set cpo&vim

function! grammarous#info_win#action_return()
    call grammarous#move_to_checked_buf(b:grammarous_preview_error.fromy+1, b:grammarous_preview_error.fromx+1)
endfunction

function! grammarous#info_win#action_fixit()
    call grammarous#fixit(b:grammarous_preview_error)
endfunction

function! grammarous#info_win#action_remove_error()
    let e = b:grammarous_preview_error
    if !grammarous#move_to_checked_buf(
        \ b:grammarous_preview_error.fromy+1,
        \ b:grammarous_preview_error.fromx+1 )
        return
    endif

    call grammarous#remove_error(e, b:grammarous_result)
endfunction

function! grammarous#info_win#action_disable_rule()
    let e = b:grammarous_preview_error
    if !grammarous#move_to_checked_buf(
        \ b:grammarous_preview_error.fromy+1,
        \ b:grammarous_preview_error.fromx+1 )
        return
    endif

    call grammarous#disable_rule(e.ruleId, b:grammarous_result)
endfunction

function! grammarous#info_win#action_help()
    echo join([
            \   "| Mappings | Description                                    |",
            \   "| -------- |:---------------------------------------------- |",
            \   "|    q     | Quit the info window                           |",
            \   "|   <CR>   | Move to the location of the error              |",
            \   "|    f     | Fix the error automatically                    |",
            \   "|    r     | Remove the error without fix                   |",
            \   "|    R     | Disable the grammar rule in the checked buffer |",
            \ ], "\n")
endfunction

function! s:get_info_buffer(e)
    return join(
        \ [
        \   "Error: " . a:e.category,
        \   "    " . a:e.msg,
        \   "",
        \   "Context:",
        \   "    " . a:e.context,
        \   "",
        \   "Correction:",
        \   "    " . split(a:e.replacements, '#')[0],
        \   "",
        \   "Press '?' in this window to show help",
        \ ],
        \ "\n")
endfunction

function! grammarous#info_win#action_quit()
    let s:do_not_preview = 1
    quit!
    unlet b:grammarous_preview_bufnr
endfunction

function! grammarous#info_win#open(e, bufnr)
    execute g:grammarous#info_win_direction g:grammarous#info_window_height . 'new' '[Grammarous]\ ' . a:e.category
    let b:grammarous_preview_original_bufnr = a:bufnr
    let b:grammarous_preview_error = a:e
    silent put =s:get_info_buffer(a:e)
    silent 1delete _
    execute 1
    syntax match GrammarousInfoSection "\%(Context\|Correction\):"
    syntax match GrammarousInfoError "Error:.*$"
    execute 'syntax match GrammarousError "' . grammarous#generate_highlight_pattern(a:e) . '"'
    setlocal nonumber bufhidden=wipe buftype=nofile readonly nolist nobuflisted noswapfile nomodifiable nomodified
    nnoremap <silent><buffer>q :<C-u>call grammarous#info_win#action_quit()<CR>
    nnoremap <silent><buffer><CR> :<C-u>call grammarous#info_win#action_return()<CR>
    nnoremap <buffer>f :<C-u>call grammarous#info_win#action_fixit()<CR>
    nnoremap <silent><buffer>r :<C-u>call grammarous#info_win#action_remove_error()<CR>
    nnoremap <silent><buffer>R :<C-u>call grammarous#info_win#action_disable_rule()<CR>
    nnoremap <buffer>? :<C-u>call grammarous#info_win#action_help()<CR>
    return bufnr('%')
endfunction

function! s:lookup_preview_bufnr()
    for b in tabpagebuflist()
        let the_buf = getbufvar(b, 'grammarous_preview_bufnr', -1)
        if the_buf != -1
            return the_buf
        endif
    endfor
    return -1
endfunction

function! grammarous#info_win#close()
    let cur_win = winnr()
    if exists('b:grammarous_preview_bufnr')
        let prev_win = bufwinnr(b:grammarous_preview_bufnr)
    else
        let the_buf = s:lookup_preview_bufnr()
        if the_buf == -1
            return 0
        endif
        let prev_win = bufwinnr(the_buf)
    endif

    if prev_win == -1
        return 0
    end

    execute prev_win . 'wincmd w'
    wincmd c
    execute cur_win . 'wincmd w'

    return 1
endfunction

function! s:do_auto_preview()
    let mode = mode()
    if mode ==? 'v' || mode ==# "\<C-v>"
        return
    endif

    if exists('s:do_not_preview')
        unlet s:do_not_preview
        return
    endif

    if !exists('b:grammarous_result') || empty(b:grammarous_result)
        autocmd! plugin-grammarous-auto-preview
        return
    endif

    call grammarous#create_update_info_window_of(b:grammarous_result)
endfunction

function! grammarous#info_win#start_auto_preview()
    augroup plugin-grammarous-auto-preview
        autocmd!
        autocmd CursorMoved <buffer> call <SID>do_auto_preview()
    augroup END
endfunction

function! grammarous#info_win#stop_auto_preview()
    silent! autocmd! plugin-grammarous-auto-preview
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo