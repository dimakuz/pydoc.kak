declare-option -docstring "name of the client in which documentation is to be displayed" \
    str docsclient

declare-option -hidden str pydocpage
# FIXME check if venc is defined
declare-option str pydoccmd pydoc3

hook -group pydoc-highlight global WinSetOption filetype=pydoc %{
    add-highlighter window/pydoc-highlight group
    add-highlighter window/pydoc-highlight/ regex ^\S.*?$ 0:blue
    add-highlighter window/pydoc-highlight/ regex '^ {3}\S.*?$' 0:default+b
    add-highlighter window/pydoc-highlight/ regex '^ {7}-[^\s,]+(,\s+-[^\s,]+)*' 0:yellow
    add-highlighter window/pydoc-highlight/ regex [-a-zA-Z0-9_.]+\([a-z0-9]+\) 0:green

    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/pydoc-highlight }
}

hook global WinSetOption filetype=pydoc %{
    hook -group pydoc-hooks window WinResize .* %{ pydoc-impl %val{bufname} %opt{pydocpage} }
    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window pydoc-hooks }
}

define-command -hidden -params 2 pydoc-impl %{ evaluate-commands %sh{
    buffer_name="$1"
    shift
    pydocout=$(mktemp "${TMPDIR:-/tmp}"/kak-pydoc-XXXXXX)
    ${kak_opt_pydoccmd} $1 > $pydocout
    printf %s\\n "
            edit -scratch '$buffer_name'
            execute-keys '%|cat<space>${pydocout}<ret>gk'
            nop %sh{rm ${pydocout}}
            set-option buffer filetype pydoc
            set-option window pydocpage '$@'
    "
}}

define-command -params ..1 \
  -shell-script-candidates %{
      find /usr/share/pydoc/ -name '*.[1-8]*' | sed 's,^.*/\(.*\)\.\([1-8][a-zA-Z]*\).*$,\1(\2),'
  } \
  -docstring %{pydoc [<page>]: pydocpage viewer wrapper
If no argument is passed to the command, the selection will be used as page
The page can be a word, or a word directly followed by a section number between parenthesis, e.g. kak(1)} \
    pydoc %{ evaluate-commands %sh{
    subject=${1-$kak_selection}
    printf %s\\n "evaluate-commands -try-client %opt{docsclient} pydoc-impl *pydoc* $subject"
} }
