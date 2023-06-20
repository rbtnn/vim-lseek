
let g:loaded_lseek = 1

command! -nargs=1 Lseek :call <SID>lseek(str2nr(<q-args>))

function! s:lseek(n) abort
    let path = expand('%')
    if !filereadable(path)
        echohl Error
        echo '[lseek] the current buffer does not exist as a file!'
        echohl None
    elseif &encoding != 'utf-8'
        echohl Error
        echo '[lseek] &encoding should be utf-8!'
        echohl None
    elseif (&fileencoding != 'cp932') && (&fileencoding != 'utf-8')
        echohl Error
        echo printf('[lseek] %s is not suppported!', &fileencoding)
        echohl None
    else
        let bytes = readblob(path, 0, a:n)
        let row = 1
        let char_count = 0
        let i = 0
        while i < len(bytes)
            if bytes[i] == 0x0a
                let i += 1
                let row += 1
                let char_count = 0
            elseif bytes[i] == 0x0d
                let i += 1
                if i < len(bytes)
                    if bytes[i] == 0x0a
                        let i += 1
                    endif
                endif
                let row += 1
                let char_count = 0
            else
                if &fileencoding == 'cp932'
                    if bytes[i] < 0x80
                        let i += 1
                        let char_count += 1
                    else
                        let i += 2
                        let char_count += 1
                    endif
                elseif &fileencoding == 'utf-8'
                    let bits = s:nr2binary(bytes[i])
                    let c = s:count_1_prefixed(bits)
                    if c == 0
                        let i += 1
                        let char_count += 1
                    else
                        let i += c
                        let char_count += 1
                    endif
                else
                    break
                endif
            endif
        endwhile
        call setcharpos('.', [0, row, char_count, 0])
    endif
endfunction

" echo s:nr2binary(99)
" [0, 1, 1, 0 ,0, 0, 1, 1]
function! s:nr2binary(x) abort
    let bits = repeat([0], 8)
    let n = 1
    for i in range(7, 0, -1)
        let bits[i] = and(a:x, n) != 0
        let n *= 2
    endfor
    return bits
endfunction

"echo s:count_1_prefixed([1, 1, 0, 0, 0, 0, 1, 1])
" 2
function! s:count_1_prefixed(bits) abort
    let c = 0
    for b in a:bits
        if b
            let c += 1
        else
            break
        endif
    endfor
    return c
endfunction
