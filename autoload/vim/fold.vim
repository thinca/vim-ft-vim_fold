function! vim#fold#level(lnum)
  if b:changedtick != get(b:, 'vim_fold_last_changedtick', -1)
    let b:vim_fold_last_changedtick = b:changedtick
    let b:vim_fold_levels = vim#fold#calculate(bufnr('%'))
  endif
  return get(b:vim_fold_levels, a:lnum, 0)
endfunction

function! vim#fold#text()
  let line = getline(v:foldstart)
  let linenr = v:foldstart + 1
  while getline(linenr) =~# '^\s*\\'
    let line .= matchstr(getline(linenr), '^\s*\\\s\{-}\zs\s\?\S.*$')
    let linenr += 1
  endwhile
  if linenr == v:foldstart + 1
    return foldtext()
  endif
  return line
endfunction

function vim#fold#calculate(bufnr) abort
  let foldmarker = getbufvar(a:bufnr, '&foldmarker')
  let [open_marker, close_marker] = split(foldmarker, ',')
  let om_len = len(open_marker)
  let cm_len = len(close_marker)
  let levels = {}
  let lines = getbufline(a:bufnr, 1, '$')
  let lnum = 0
  let next_line = lines[lnum]
  let cur_lv = 0
  let endl = line('$')

  let open_pat = '^\s*:\?\s*\%(fu\%[nction]\>\|aug\%[roup]\)'
  let close_pat = '^\s*:\?\s*\%(endf\%[unction]\>\|aug\%[roup]\s\+END\)'

  while lnum < endl
    let lnum += 1
    let cur_line = next_line
    let next_line = get(lines, lnum, '')
    let ch_lv = 0

    " marker
    let col = 0
    while 1
      let om_pos = stridx(cur_line, open_marker, col)
      let cm_pos = stridx(cur_line, close_marker, col)
      if om_pos < 0 && cm_pos < 0
        break
      endif
      let is_open = cm_pos < 0 || (0 <= om_pos && om_pos < cm_pos)
      let col = is_open ? om_pos + om_len : cm_pos + cm_len
      let marker_lv = matchstr(cur_line, '^\d\+', col)
      let col += len(marker_lv)
      let marker_lv = str2nr(marker_lv)
      if is_open
        if marker_lv is# 0
          let ch_lv += 1
        else
          let levels[lnum] = '>' . marker_lv
          let cur_lv = marker_lv
        endif
      else
        if marker_lv is# 0
          let ch_lv -= 1
        else
          let levels[lnum] = '<' . marker_lv
          let cur_lv = marker_lv - 1
        endif
      endif
    endwhile

    if has_key(levels, lnum)
      let cur_lv = max([cur_lv + ch_lv, 0])
      continue
    endif

    if cur_line =~# close_pat
      let ch_lv -= 1
    elseif cur_line =~# open_pat
      let ch_lv += 1
    endif
    if cur_line =~# '^\s*\\'
      if next_line !~# '^\s*\\'
        let ch_lv -= 1
      endif
    elseif next_line =~# '^\s*\\'
      let ch_lv += 1
    endif

    if ch_lv < 0
      let levels[lnum] = '<' . cur_lv
    elseif 0 < ch_lv
      let levels[lnum] = '>' . (cur_lv + ch_lv)
    else
      let levels[lnum] = cur_lv + ch_lv
    endif
    let cur_lv = max([cur_lv + ch_lv, 0])
  endwhile
  return levels
endfunction
