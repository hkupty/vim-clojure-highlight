" vim-clojure-highlight

if !exists('g:clojure_highlight_references')
  let g:clojure_highlight_references = 1
endif

if !exists('g:clojure_highlight_local_vars')
  let g:clojure_highlight_local_vars = 1
endif

function! AsyncCljHighlightExec(msg)
  let fst = a:msg[0]
  if get(fst, 'value', '') !=# ''
    exec eval(fst.value)
    let &syntax = &syntax
  elseif get(fst, 'err', '') !=# ''
    echohl ErrorMSG
    echo fst.err
    echohl NONE
  endif
endfunction

function! AsyncCljRequestHighlight(...)
  if a:0 > 0
    let fst = a:1
    if get(fst, 'err', '') !=# ''
      echohl ErrorMSG
      echo fst.err
      echohl NONE
      return
    endif
  endif

  let ns = AcidGetNs()
  let opts = g:clojure_highlight_local_vars ? '' : ' :local-vars false'
  call AcidSendNrepl({"op": "eval", "code": "(async-clj-highlight/ns-syntax-command '" . ns . opts . ")"}, 'VimFn', 'AsyncCljHighlightExec')
endfunction

function! AsyncCljHighlightPrepare(msg)
  let exists = a:msg[0]['value']
  if exists =~ 'nil'
      let buf = join(readfile(globpath(&runtimepath, 'clj/async_clj_highlight.clj')), "\n")
      call AcidSendNrepl({'op': 'eval', 'code': "(do ". buf . ")"}, 'VimFn', 'AsyncCljRequestHighlight')
  endif
  call AsyncCljRequestHighlight()
endfunction

function! s:syntax_match_references()
  if g:clojure_highlight_references
    call AcidSendNrepl({'op': 'eval', 'code': "(find-ns 'vim-clojure-highlight)"}, 'VimFn', 'AsyncCljHighlightPrepare')
  endif
endfunction

function! s:toggle_clojure_highlight_references()
  let g:clojure_highlight_references = !g:clojure_highlight_references

  if g:clojure_highlight_references
    call s:syntax_match_references()
  else
    unlet! b:clojure_syntax_keywords b:clojure_syntax_without_core_keywords
    let &syntax = &syntax
  endif
endfunction

augroup vim_clojure_highlight
  autocmd!
  autocmd BufRead *.clj ClojureHighlightReferences
augroup END

command! -bar ToggleClojureHighlightReferences call s:toggle_clojure_highlight_references()
command! -bar ClojureHighlightReferences call s:syntax_match_references()
