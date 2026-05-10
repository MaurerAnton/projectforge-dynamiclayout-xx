(* DynamicLayout OCaml API — generate layout JSON from OCaml code.
 *
 * Single-file module. Zero dependencies outside stdlib.
 * Works on OCaml 4.14+.
 *
 * Example:
 *   open DynamicLayout
 *   let b = begin_ "My Page" in
 *   let b = fieldset b "Info" in
 *   let b = label b "Hello from OCaml!" in
 *   let b = end_fieldset b in
 *   let b = button b "ok" "OK" "primary" true in
 *   print_endline (end_layout b)
 *)

type builder = {
  buf: Buffer.t;
  depth: int ref;
  comma: bool ref;
  cnt: int ref;
}

let putc b c = Buffer.add_char b.buf c; b
let puts b s = Buffer.add_string b.buf s; b
let indent b =
  let _ = putc b '\n' in
  for _ = 1 to !(b.depth) do ignore (puts b "  ") done; b

let cm b = if !(b.comma) then (putc b ','; b.comma := false; b) else b

let esc b s =
  let _ = putc b '"' in
  String.iter (function
    | '"' -> puts b "\\\""; | '\\' -> puts b "\\\\"; | '\n' -> puts b "\\n"
    | '\r' -> puts b "\\r"; | '\t' -> puts b "\\t"; | c -> putc b c) s;
  putc b '"'

let kv b k v =
  let _ = cm b in let _ = putc b ',' in let _ = indent b in
  let _ = esc b k in let _ = puts b ": " in let _ = esc b v in
  b.comma := true; b

let kvint b k v = kv b k (string_of_int v)
let kvbool b k = kv b k "true"

let obj b =
  let _ = cm b in let _ = putc b ',' in let _ = indent b in
  let _ = putc b '{' in b.depth := !(b.depth) + 1; b.comma := false; b

let close_obj b =
  b.depth := !(b.depth) - 1; let _ = indent b in let _ = putc b '}' in
  b.comma := true; b

let arr b k =
  let _ = cm b in let _ = putc b ',' in let _ = indent b in
  let _ = esc b k in let _ = puts b ": [" in
  b.depth := !(b.depth) + 1; b.comma := false; b

let close_arr b =
  b.depth := !(b.depth) - 1; let _ = indent b in let _ = putc b ']' in
  b.comma := true; b

let key b prefix =
  b.cnt := !(b.cnt) + 1; Printf.sprintf "%s_%d" prefix !(b.cnt)

let begin_ title =
  let b = { buf = Buffer.create 4096; depth = ref 0; comma = ref false; cnt = ref 0 } in
  let _ = puts b "{\"ui\":{" in
  b.depth := 2; b.comma := false;
  let _ = kv b "title" title in arr b "layout"

let end_layout b =
  let _ = close_arr b in b.comma := false; let _ = putc b ',' in
  let _ = puts b "\"translations\":{}," in
  let _ = puts b "\"userAccess\":{\"cancel\":true}" in
  let _ = puts b "}}" in Buffer.contents b.buf

let fieldset b title =
  let _ = obj b in
  let _ = kv b "type" "FIELDSET" in let _ = kv b "key" (key b "fs") in
  let _ = kv b "title" title in arr b "content"

let end_fieldset b = close_obj (close_arr b)

let label b text =
  let _ = obj b in
  let _ = kv b "type" "LABEL" in let _ = kv b "key" (key b "l") in
  close_obj (kv b "label" text)

let alert b msg color =
  let _ = obj b in
  let _ = kv b "type" "ALERT" in let _ = kv b "key" (key b "a") in
  close_obj (kv b "color" color (kv b "message" msg))

let badge b title color =
  let _ = obj b in
  let _ = kv b "type" "BADGE" in let _ = kv b "key" (key b "bd") in
  close_obj (kv b "color" color (kv b "title" title))

let spacer b px =
  let _ = obj b in
  let _ = kv b "type" "SPACER" in let _ = kv b "key" (key b "sp") in
  close_obj (kvint b "width" px)

let input b id label required =
  let _ = obj b in
  let _ = kv b "type" "INPUT" in let _ = kv b "key" (key b "i") in
  let b = kv b "label" label (kv b "id" id) in
  close_obj (if required then kvbool b "required" else b)

let checkbox b id label =
  let _ = obj b in
  let _ = kv b "type" "CHECKBOX" in let _ = kv b "key" (key b "cb") in
  close_obj (kv b "label" label (kv b "id" id))

let textarea b id label rows =
  let _ = obj b in
  let _ = kv b "type" "TEXTAREA" in let _ = kv b "key" (key b "ta") in
  let b = kv b "label" label (kv b "id" id) in
  close_obj (if rows > 0 then kvint b "rows" rows else b)

let rating b id label =
  let _ = obj b in
  let _ = kv b "type" "RATING" in let _ = kv b "key" (key b "rt") in
  close_obj (kv b "label" label (kv b "id" id))

let button b id title color is_default =
  let _ = obj b in
  let _ = kv b "type" "BUTTON" in let _ = kv b "key" (key b "btn") in
  let b = kv b "color" color (kv b "title" title (kv b "id" id)) in
  close_obj (if is_default then kvbool b "default" else b)

let section b title text = end_fieldset (label (fieldset b title) text)
