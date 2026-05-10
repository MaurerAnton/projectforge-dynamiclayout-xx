#!/usr/bin/env bash
# DynamicLayout Bash API — generate layout JSON from shell scripts.
# Single-file. Zero dependencies (bash 4.0+ builtins only).
#
# Example:
#   source dynamiclayout.sh
#   dl_begin "My Page"
#   dl_fieldset "Info"
#   dl_label "Hello from Bash!"
#   dl_end_fieldset
#   dl_button "ok" "OK" "primary" true
#   dl_end
#   echo "$DL_BUF"

dl_putc() { DL_BUF+="$1"; }
dl_puts() { DL_BUF+="$1"; }
dl_indent() { DL_BUF+=$'\n'; for ((i=0; i<DL_DEPTH; i++)); do DL_BUF+='  '; done; }
dl_cm() { [[ "$DL_COMMA" == true ]] && DL_BUF+=','; DL_COMMA=false; }
dl_esc() { local s="$1"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; s="${s//$'\n'/\\n}"; DL_BUF+="\"$s\""; }

dl_kv() { dl_cm; DL_BUF+=','; dl_indent; dl_esc "$1"; dl_puts ': '; dl_esc "$2"; DL_COMMA=true; }
dl_kvint() { dl_cm; DL_BUF+=','; dl_indent; dl_esc "$1"; dl_puts ": $2"; DL_COMMA=true; }
dl_kvbool() { dl_cm; DL_BUF+=','; dl_indent; dl_esc "$1"; dl_puts ': true'; DL_COMMA=true; }
dl_obj() { dl_cm; DL_BUF+=','; dl_indent; DL_BUF+='{'; ((DL_DEPTH++)); DL_COMMA=false; }
dl_co() { ((DL_DEPTH--)); dl_indent; DL_BUF+='}'; DL_COMMA=true; }
dl_arr() { dl_cm; DL_BUF+=','; dl_indent; dl_esc "$1"; dl_puts ': ['; ((DL_DEPTH++)); DL_COMMA=false; }
dl_ca() { ((DL_DEPTH--)); dl_indent; DL_BUF+=']'; DL_COMMA=true; }
dl_key() { ((DL_CNT++)); echo "${1}_${DL_CNT}"; }

dl_begin() {
    DL_BUF='{"ui":{'
    DL_DEPTH=2; DL_COMMA=false; DL_CNT=0
    dl_kv "title" "$1"
    dl_arr "layout"
}

dl_end() {
    dl_ca; DL_COMMA=false; DL_BUF+=','
    dl_puts '"translations":{},'
    dl_puts '"userAccess":{"cancel":true}'
    dl_puts '}}'
}

dl_fieldset() { dl_obj; dl_kv "type" "FIELDSET"; dl_kv "key" "$(dl_key fs)"; dl_kv "title" "$1"; dl_arr "content"; }
dl_end_fieldset() { dl_ca; dl_co; }
dl_label() { dl_obj; dl_kv "type" "LABEL"; dl_kv "key" "$(dl_key l)"; dl_kv "label" "$1"; dl_co; }
dl_alert() { dl_obj; dl_kv "type" "ALERT"; dl_kv "key" "$(dl_key a)"; dl_kv "message" "$1"; dl_kv "color" "${2:-info}"; dl_co; }
dl_badge() { dl_obj; dl_kv "type" "BADGE"; dl_kv "key" "$(dl_key bd)"; dl_kv "title" "$1"; dl_kv "color" "${2:-primary}"; dl_co; }
dl_spacer() { dl_obj; dl_kv "type" "SPACER"; dl_kv "key" "$(dl_key sp)"; dl_kvint "width" "${1:-20}"; dl_co; }
dl_input() { dl_obj; dl_kv "type" "INPUT"; dl_kv "key" "$(dl_key i)"; dl_kv "id" "$1"; dl_kv "label" "$2"; [[ "${3:-}" == true ]] && dl_kvbool "required"; dl_co; }
dl_checkbox() { dl_obj; dl_kv "type" "CHECKBOX"; dl_kv "key" "$(dl_key cb)"; dl_kv "id" "$1"; dl_kv "label" "${2:-}"; dl_co; }
dl_textarea() { dl_obj; dl_kv "type" "TEXTAREA"; dl_kv "key" "$(dl_key ta)"; dl_kv "id" "$1"; dl_kv "label" "$2"; [[ "${3:-0}" -gt 0 ]] && dl_kvint "rows" "$3"; dl_co; }
dl_rating() { dl_obj; dl_kv "type" "RATING"; dl_kv "key" "$(dl_key rt)"; dl_kv "id" "$1"; dl_kv "label" "${2:-}"; dl_co; }
dl_button() { dl_obj; dl_kv "type" "BUTTON"; dl_kv "key" "$(dl_key btn)"; dl_kv "id" "$1"; dl_kv "title" "$2"; dl_kv "color" "$3"; [[ "${4:-}" == true ]] && dl_kvbool "default"; dl_co; }
dl_section() { dl_fieldset "$1"; dl_label "$2"; dl_end_fieldset; }
