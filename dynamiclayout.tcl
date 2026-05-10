# DynamicLayout Tcl API — generate layout JSON from Tcl code.
# Single-file. Zero dependencies. Works on Tcl 8.6+.
#
# Example:
#   source dynamiclayout.tcl
#   dl_begin "My Page"
#   dl_fieldset "Info"
#   dl_label "Hello from Tcl!"
#   dl_end_fieldset
#   dl_button "ok" "OK" "primary" 1
#   puts [dl_end]

variable DL_BUF ""; variable DL_DEPTH 0; variable DL_COMMA 0; variable DL_CNT 0

proc dl_putc {c} { variable DL_BUF; append DL_BUF $c }
proc dl_puts {s} { variable DL_BUF; append DL_BUF $s }
proc dl_indent {} { variable DL_BUF; variable DL_DEPTH; append DL_BUF \n; for {set i 0} {$i < $DL_DEPTH} {incr i} { append DL_BUF "  " } }
proc dl_cm {} { variable DL_COMMA; if {$DL_COMMA} { dl_putc "," }; set DL_COMMA 0 }
proc dl_esc {s} { dl_putc "\""; regsub -all {\\} $s {\\\\} s; regsub -all {"} $s {\"} s; regsub -all {\n} $s {\\n} s; dl_puts $s; dl_putc "\"" }
proc dl_kv {k v} { dl_cm; dl_putc ","; dl_indent; dl_esc $k; dl_puts ": "; dl_esc $v; variable DL_COMMA; set DL_COMMA 1 }
proc dl_kvint {k v} { dl_cm; dl_putc ","; dl_indent; dl_esc $k; dl_puts ": $v"; variable DL_COMMA; set DL_COMMA 1 }
proc dl_kvbool {k} { dl_cm; dl_putc ","; dl_indent; dl_esc $k; dl_puts ": true"; variable DL_COMMA; set DL_COMMA 1 }
proc dl_obj {} { dl_cm; dl_putc ","; dl_indent; dl_putc "\{"; variable DL_DEPTH; incr DL_DEPTH; variable DL_COMMA; set DL_COMMA 0 }
proc dl_co {} { variable DL_DEPTH; incr DL_DEPTH -1; dl_indent; dl_putc "\}"; variable DL_COMMA; set DL_COMMA 1 }
proc dl_arr {k} { dl_cm; dl_putc ","; dl_indent; dl_esc $k; dl_puts ": ["; variable DL_DEPTH; incr DL_DEPTH; variable DL_COMMA; set DL_COMMA 0 }
proc dl_ca {} { variable DL_DEPTH; incr DL_DEPTH -1; dl_indent; dl_putc "\]"; variable DL_COMMA; set DL_COMMA 1 }
proc dl_key {p} { variable DL_CNT; incr DL_CNT; return "${p}_${DL_CNT}" }

proc dl_begin {title} { variable DL_BUF; set DL_BUF "{\"ui\":\{"; variable DL_DEPTH; set DL_DEPTH 2; variable DL_COMMA; set DL_COMMA 0; variable DL_CNT; set DL_CNT 0; dl_kv "title" $title; dl_arr "layout" }
proc dl_end {} { dl_ca; variable DL_COMMA; set DL_COMMA 0; dl_putc ","; dl_puts "\"translations\":\{\},"; dl_puts "\"userAccess\":\{\"cancel\":true\}"; dl_puts "\}\}"; variable DL_BUF; set s $DL_BUF; return $s }

proc dl_fieldset {title} { dl_obj; dl_kv "type" "FIELDSET"; dl_kv "key" [dl_key fs]; dl_kv "title" $title; dl_arr "content" }
proc dl_end_fieldset {} { dl_ca; dl_co }
proc dl_label {text} { dl_obj; dl_kv "type" "LABEL"; dl_kv "key" [dl_key l]; dl_kv "label" $text; dl_co }
proc dl_alert {msg {color info}} { dl_obj; dl_kv "type" "ALERT"; dl_kv "key" [dl_key a]; dl_kv "message" $msg; dl_kv "color" $color; dl_co }
proc dl_badge {title {color primary}} { dl_obj; dl_kv "type" "BADGE"; dl_kv "key" [dl_key bd]; dl_kv "title" $title; dl_kv "color" $color; dl_co }
proc dl_spacer {{px 20}} { dl_obj; dl_kv "type" "SPACER"; dl_kv "key" [dl_key sp]; dl_kvint "width" $px; dl_co }
proc dl_input {id label {required 0}} { dl_obj; dl_kv "type" "INPUT"; dl_kv "key" [dl_key i]; dl_kv "id" $id; dl_kv "label" $label; if {$required} { dl_kvbool "required" }; dl_co }
proc dl_checkbox {id {label ""}} { dl_obj; dl_kv "type" "CHECKBOX"; dl_kv "key" [dl_key cb]; dl_kv "id" $id; dl_kv "label" $label; dl_co }
proc dl_rating {id {label ""}} { dl_obj; dl_kv "type" "RATING"; dl_kv "key" [dl_key rt]; dl_kv "id" $id; dl_kv "label" $label; dl_co }
proc dl_button {id title color {is_default 0}} { dl_obj; dl_kv "type" "BUTTON"; dl_kv "key" [dl_key btn]; dl_kv "id" $id; dl_kv "title" $title; dl_kv "color" $color; if {$is_default} { dl_kvbool "default" }; dl_co }
proc dl_section {title text} { dl_fieldset $title; dl_label $text; dl_end_fieldset }
