command! CommentMethod :call s:generate_method(line('.'))
command! CommentField :call s:generate_field(line('.'))
command! CommentClass :call s:generate_class(line('.'))
command! Comment :call s:comment_all()

let s:p_symbol = '\([a-zA-Z0-9_\[\]<?>]\+\)'
let s:p_param = '\(([^)]*)\)'
let s:p_method = s:p_symbol . ' ' . s:p_symbol . s:p_param
let s:p_arg = '\(final \)\?[a-zA-Z0-9_]\+ ' . s:p_symbol . '[, ]*\(.*\)'
let s:p_field = s:p_symbol . '\s*[=;]'
let s:p_class = '\(class \|interface \)' . s:p_symbol
let s:p_comment = '\(/\+\)'

function! s:comment_all()
    let lnum = 1
    let scop = 0
    let sum = line("$")
    while lnum < sum
        let text = getline(lnum)
        if s:matchclass(lnum, text, scop) > 0
            call s:generate_class(lnum)
        elseif s:matchfield(lnum, text, scop) > 0
            call s:generate_field(lnum)
        elseif s:matchmethod(lnum, text, scop) > 0
            call s:generate_method(lnum)
        endif
        let newsum = line("$")
        let lnum += newsum - sum
        let sum = newsum
        let lnum += 1
        if match(text, "{") > 0
            let scop += 1
        endif
        if match(text, "}") > 0
            let scop -= 1
        endif
    endwhile
endfunction

function! s:matchclass(lnum, text, scop)
    let k = s:skip_ann(a:lnum)
    if (len(matchlist(getline(k), s:p_comment)) > 0)
        return 0
    endif
    let lst = matchlist(a:text, s:p_class)
    if len(lst) > 0 && a:scop == 0
        return 1
    endif
    return 0
endfunction

function! s:matchfield(lnum, text, scop)
    let k = s:skip_ann(a:lnum)
    if (len(matchlist(getline(k), s:p_comment)) > 0)
        return 0
    endif
    let lst = matchlist(a:text, s:p_field)
    if len(lst) > 0 && a:scop == 1
        return 1
    endif
    return 0
endfunction

function! s:matchmethod(lnum, text, scop)
    let k = s:skip_ann(a:lnum)
    if (len(matchlist(getline(k), s:p_comment)) > 0)
        return 0
    endif
    let lst = matchlist(a:text, s:p_method)
    if len(lst) > 0 && a:scop == 1
        return 1
    endif
    return 0
endfunction

function! s:skip_ann(l)
    let i = a:l - 1
    let text = getline(i)
    while len(matchstr(text, '@')) > 0
        let i = i - 1
        let text = getline(i)
    endwhile
    return i
endfunction 

function! s:generate_class(l)
    let i = indent(a:l)
    let text = getline(a:l)
    let lst = matchlist(text, s:p_class)
    let type = lst[1]
    let class_name = lst[2]
    if type == 'class '
        let comment = ['/**', ' * The Class ' . class_name . '.', ' *', ' * @version 1.0', ' */']
    else
        let comment = ['/**', ' * The Interface ' . class_name . '.', ' *', ' * @version 1.0', ' */']
    endif
    let s = s:skip_ann(a:l)
    call append(s, comment)
    call cursor(a:l+1, i+3)
endfunction

function! s:generate_field(l)
    let i = indent(a:l)
    let pre = repeat(' ',i)
    let text = getline(a:l)
    let lst = matchlist(text, s:p_field)
    let constant_flag = len(matchstr(text, 'final')) > 0
    let field_name = lst[1]
    if constant_flag
        let comment = [pre.'/** The Constant '.field_name.'. */']
    else
        let comment = [pre.'/** The '.field_name.'. */']
    endif
    let s = s:skip_ann(a:l)
    call append(s, comment)
    call cursor(a:l+1,i+3)
endfunction

function! s:generate_method(l)
    let i = indent(a:l)
    let pre = repeat(' ',i)
    let text = getline(a:l)
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
        let s = s:skip_ann(a:l)
        call append(s, comment)
        call cursor(a:l+1,i+3)
    endif
endfunction
