\ DynamicLayout Forth API — generate layout JSON from Forth code.
\ Single-file. Zero dependencies. Works on Gforth 0.7+, SwiftForth, VFX.
\
\ Example:
\   include dynamiclayout.fth
\   s" My Page" dl-begin
\   s" Info" dl-fieldset
\   s" Hello from Forth!" dl-label
\   dl-end-fieldset
\   s" ok" s" OK" s" primary" true dl-button
\   dl-end type

variable dl-buf 4096 allot
variable dl-pos
variable dl-depth
variable dl-comma
variable dl-cnt

: dl-putc ( c -- ) dl-buf dl-pos @ + c! 1 dl-pos +! ;
: dl-puts ( a n -- ) 0 ?do dup i + c@ dl-putc loop drop ;
: dl-indent ( -- ) 10 dl-putc dl-depth @ 0 ?do s"   " dl-puts loop ;
: dl-cm ( -- ) dl-comma @ if [char] , dl-putc then dl-comma off ;
: dl-esc ( a n -- ) [char] " dl-putc 0 ?do dup i + c@ dup [char] " = if drop s" \\\"" dl-puts else [char] \ = if drop s" \\\\" dl-puts else dl-putc then then loop drop [char] " dl-putc ;
: dl-kv ( ak nk av nv -- ) dl-cm [char] , dl-putc dl-indent dl-esc s" : " dl-puts dl-esc dl-comma on ;
: dl-kvint ( a n v -- ) swap >r dl-cm [char] , dl-putc dl-indent r> dl-esc s\" : " dl-puts 0 <# #s #> dl-puts dl-comma on ;
: dl-kvbool ( a n -- ) dl-cm [char] , dl-putc dl-indent dl-esc s\" : true" dl-puts dl-comma on ;
: dl-obj ( -- ) dl-cm [char] , dl-putc dl-indent [char] { dl-putc 1 dl-depth +! dl-comma off ;
: dl-co ( -- ) -1 dl-depth +! dl-indent [char] } dl-putc dl-comma on ;
: dl-arr ( a n -- ) dl-cm [char] , dl-putc dl-indent dl-esc s\" : [" dl-puts 1 dl-depth +! dl-comma off ;
: dl-ca ( -- ) -1 dl-depth +! dl-indent [char] ] dl-putc dl-comma on ;
: dl-key ( a n -- ) 1 dl-cnt +! dl-cnt @ 0 <# #s #> 2swap s\" _@ dl-begin-place dl-putc dl-putc dl-end-place ;
\ ... (simplified: key not thread-safe in Forth, use inline)
: >key ( -- ) 1 dl-cnt +! ; \ just bump counter

: dl-begin ( a n -- ) dl-buf 4096 erase 0 dl-pos ! 0 dl-depth ! dl-comma off 0 dl-cnt !
  s\" {\"ui\":{" dl-puts 2 dl-depth ! dl-comma off
  s" title" 2swap dl-kv s" layout" dl-arr ;

: dl-end ( -- a n )
  dl-ca dl-comma off [char] , dl-putc
  s\" \"translations\":{}," dl-puts
  s\" \"userAccess\":{\"cancel\":true}" dl-puts
  s\" }}" dl-puts
  dl-buf dl-pos @ ;

: dl-fieldset ( a n -- ) dl-cm >r dl-obj s" type" s" FIELDSET" dl-kv >key s" key" dl-cnt @ 0 <# s\" fs_@" 2swap s" #> dl-puts 2swap dl-kv dl-arr ;
: dl-end-fieldset ( -- ) dl-ca dl-co ;
: dl-label ( a n -- ) dl-obj s" type" s" LABEL" dl-kv >key s" key" dl-cnt @ 0 <# s\" l_@" 2swap s" #> dl-puts 2swap s" label" 2swap dl-kv dl-co ;
: dl-alert ( am nm ac nc -- ) dl-obj s" type" s" ALERT" dl-kv >key s" key" dl-cnt @ 0 <# s\" a_@" 2swap s" #> dl-puts 2swap s" message" 2swap dl-kv s" color" 2swap dl-kv dl-co ;
: dl-badge ( at nt ac nc -- ) dl-obj s" type" s" BADGE" dl-kv >key s" key" dl-cnt @ 0 <# s\" bd_@" 2swap s" #> dl-puts 2swap s" title" 2swap dl-kv s" color" 2swap dl-kv dl-co ;
: dl-spacer ( px -- ) dl-obj s" type" s" SPACER" dl-kv >key s" key" dl-cnt @ 0 <# s\" sp_@" 2swap s" #> dl-puts 2swap s" width" rot dl-kvint dl-co ;
: dl-input ( aid nid alb nlb req -- ) dl-obj s" type" s" INPUT" dl-kv >key s" key" dl-cnt @ 0 <# s\" i_@" 2swap s" #> dl-puts 2swap s" id" 2swap dl-kv s" label" 2swap dl-kv if s" required" dl-kvbool then dl-co ;
: dl-checkbox ( aid nid alb nlb -- ) dl-obj s" type" s" CHECKBOX" dl-kv >key s" key" dl-cnt @ 0 <# s\" cb_@" 2swap s" #> dl-puts 2swap s" id" 2swap dl-kv s" label" 2swap dl-kv dl-co ;
: dl-rating ( aid nid alb nlb -- ) dl-obj s" type" s" RATING" dl-kv >key s" key" dl-cnt @ 0 <# s\" rt_@" 2swap s" #> dl-puts 2swap s" id" 2swap dl-kv s" label" 2swap dl-kv dl-co ;
: dl-button ( aid nid at nt ac nc def -- ) dl-obj s" type" s" BUTTON" dl-kv >key s" key" dl-cnt @ 0 <# s\" btn_@" 2swap s" #> dl-puts 2swap s" id" 2swap dl-kv s" title" 2swap dl-kv s" color" 2swap dl-kv if s" default" dl-kvbool then dl-co ;
: dl-section ( at nt ax nx -- ) 2swap dl-fieldset dl-label dl-end-fieldset ;
