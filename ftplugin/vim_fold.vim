if exists('b:undo_ftplugin')
  let b:undo_ftplugin .= ' | '
else
  let b:undo_ftplugin = ''
endif
let b:undo_ftplugin .= 'setl fdm< fde< fdt<'


setlocal foldmethod=expr foldexpr=vim#fold#level(v:lnum)
setlocal foldtext=vim#fold#text()
