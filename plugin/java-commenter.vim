command! CommentMethod :call s:generate_method()
command! CommentField :call s:generate_field()
command! CommentClass :call s:generate_class()

let s:p_symbol = '\([a-zA-Z0-9_\[\]<?>]\+\)'
let s:p_param = '\(([^)]*)\)'
let s:p_method = s:p_symbol . ' ' . s:p_symbol . s:p_param
let s:p_arg = '\(final \)\?[a-zA-Z0-9_]\+ ' . s:p_symbol . '[, ]*\(.*\)'
let s:p_field = s:p_symbol . '\s*[=;]'
let s:p_class = '\(class \|interface \)' . s:p_symbol

function! s:skip_ann(l)
    let i = a:l - 1
    let text = getline(i)
    while len(matchstr(text, '@')) > 0
        let i = i - 1
        let text = getline(i)
    endwhile
    return i
endfunction 

function! s:generate_class()
    let l = line('.')
    let i = indent(l)
    let text = getline(l)
    let lst = matchlist(text, s:p_class)
    let type = lst[1]
    let class_name = lst[2]
    if type == 'class '
        let comment = ['/**', ' * The Class ' . class_name . '.', ' *', ' * @version 1.0', ' */']
    else
        let comment = ['/**', ' * The Interface ' . class_name . '.', ' *', ' * @version 1.0', ' */']
    endif
    let s = s:skip_ann(l)
    call append(s, comment)
    call cursor(l+1, i+3)
endfunction

function! s:generate_field()
    let l = line('.')
    let i = indent(l)
    let pre = repeat(' ',i)
    let text = getline(l)
    let lst = matchlist(text, s:p_field)
    let constant_flag = len(matchstr(text, 'final')) > 0
    let field_name = lst[1]
    if constant_flag
        let comment = [pre.'/** The Constant '.field_name.'. */']
    else
        let comment = [pre.'/** The '.field_name.'. */']
    endif
    let s = s:skip_ann(l)
    call append(s, comment)
    call cursor(l+1,i+3)
endfunction

function! s:generate_method()
    let l    = line('.')
    let i    = indent(l)
    let pre  = repeat(' ',i)
    let text = getline(l)
    let lst = matchlist(text, s:p_method)
    if len(lst) > 0
        let return_var = lst[1]
        let method_name = lst[2]
        let return_flag = return_var != 'void'

        "handle method name
        let name = [pre.' * Method '.method_name.'.', pre.' *']

        "handle parameters
        let params = lst[3]
        let vars = []
        let ml = matchlist(params, s:p_arg)
        while ml!=[]
            let [_,_,var;rest]= ml
            let vars += [pre.' * @param '.var.' the '.var]
            let ml = matchlist(rest, s:p_arg, 0)
        endwhile
        if len(vars) > 0
            let vars += [pre.' *']
        endif

        "build the whole comment handl return value
        let comment = [pre.'/**'] + name + vars
        if return_flag
            let comment += [pre.' * @return the '.return_var]
        endif
        let comment += [pre.' */']
        let s = s:skip_ann(l)
        call append(s, comment)
        call cursor(l+1,i+3)
    endif
endfunction
