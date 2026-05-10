# DynamicLayout R API — generate layout JSON from R code.
#
# Single-file. Zero dependencies outside base R.
# Works on R 4.0+.
#
# Example:
#   source("dynamiclayout.R")
#   b <- dl_begin("My Page")
#   dl_fieldset(b, "Info")
#   dl_label(b, "Hello from R!")
#   dl_end_fieldset(b)
#   dl_button(b, "ok", "OK", "primary", TRUE)
#   cat(dl_end(b), "\n")

dl_put <- function(b, x) { b$buf <- paste0(b$buf, x); b }

dl_indent <- function(b) {
  b$buf <- paste0(b$buf, "\n", paste(rep("  ", b$depth), collapse=""))
  b
}

dl_cm <- function(b) {
  if (b$comma) b$buf <- paste0(b$buf, ",")
  b$comma <- FALSE; b
}

dl_esc <- function(b, s) {
  s <- gsub("\\\\", "\\\\\\\\", s)
  s <- gsub('"', '\\\\"', s)
  s <- gsub("\n", "\\\\n", s)
  b$buf <- paste0(b$buf, '"', s, '"')
  b
}

dl_kv <- function(b, key, val) {
  b <- dl_cm(b); b$buf <- paste0(b$buf, ","); b <- dl_indent(b)
  b <- dl_esc(b, key); b$buf <- paste0(b$buf, ": "); b <- dl_esc(b, val)
  b$comma <- TRUE; b
}

dl_kvint <- function(b, key, val) {
  b <- dl_cm(b); b$buf <- paste0(b$buf, ","); b <- dl_indent(b)
  b <- dl_esc(b, key); b$buf <- paste0(b$buf, ": ", val)
  b$comma <- TRUE; b
}

dl_kvbool <- function(b, key) {
  b <- dl_cm(b); b$buf <- paste0(b$buf, ","); b <- dl_indent(b)
  b <- dl_esc(b, key); b$buf <- paste0(b$buf, ": true")
  b$comma <- TRUE; b
}

dl_obj <- function(b) {
  b <- dl_cm(b); b$buf <- paste0(b$buf, ","); b <- dl_indent(b)
  b$buf <- paste0(b$buf, "{"); b$depth <- b$depth + 1; b$comma <- FALSE; b
}

dl_co <- function(b) {
  b$depth <- b$depth - 1; b <- dl_indent(b); b$buf <- paste0(b$buf, "}"); b$comma <- TRUE; b
}

dl_arr <- function(b, key) {
  b <- dl_cm(b); b$buf <- paste0(b$buf, ","); b <- dl_indent(b)
  b <- dl_esc(b, key); b$buf <- paste0(b$buf, ": [")
  b$depth <- b$depth + 1; b$comma <- FALSE; b
}

dl_ca <- function(b) {
  b$depth <- b$depth - 1; b <- dl_indent(b); b$buf <- paste0(b$buf, "]"); b$comma <- TRUE; b
}

dl_key <- function(b, prefix) {
  b$counter <- b$counter + 1
  paste0(prefix, "_", b$counter)
}

# Public API
dl_begin <- function(title) {
  b <- list(buf = "", depth = 0, comma = FALSE, counter = 0)
  b$buf <- '{"ui":{'
  b$depth <- 2; b$comma <- FALSE
  b <- dl_kv(b, "title", title)
  b <- dl_arr(b, "layout")
  b
}

dl_end <- function(b) {
  b <- dl_ca(b)
  b$comma <- FALSE; b$buf <- paste0(b$buf, ',')
  b$buf <- paste0(b$buf, '"translations":{},')
  b$buf <- paste0(b$buf, '"userAccess":{"cancel":true}')
  b$buf <- paste0(b$buf, '}}')
  b$buf
}

dl_fieldset <- function(b, title) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "FIELDSET"); b <- dl_kv(b, "key", dl_key(b, "fs"))
  b <- dl_kv(b, "title", title); b <- dl_arr(b, "content"); b
}
dl_end_fieldset <- function(b) { b <- dl_ca(b); b <- dl_co(b); b }

dl_row <- function(b) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "ROW"); b <- dl_kv(b, "key", dl_key(b, "r")); b <- dl_arr(b, "content"); b
}
dl_end_row <- function(b) { b <- dl_ca(b); b <- dl_co(b); b }

dl_label <- function(b, text) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "LABEL"); b <- dl_kv(b, "key", dl_key(b, "l"))
  b <- dl_kv(b, "label", text); b <- dl_co(b); b
}
dl_alert <- function(b, msg, color = "info") {
  b <- dl_obj(b); b <- dl_kv(b, "type", "ALERT"); b <- dl_kv(b, "key", dl_key(b, "a"))
  b <- dl_kv(b, "message", msg); b <- dl_kv(b, "color", color); b <- dl_co(b); b
}
dl_badge <- function(b, title, color = "primary") {
  b <- dl_obj(b); b <- dl_kv(b, "type", "BADGE"); b <- dl_kv(b, "key", dl_key(b, "bd"))
  b <- dl_kv(b, "title", title); b <- dl_kv(b, "color", color); b <- dl_co(b); b
}
dl_spacer <- function(b, px = 20) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "SPACER"); b <- dl_kv(b, "key", dl_key(b, "sp"))
  b <- dl_kvint(b, "width", px); b <- dl_co(b); b
}

dl_input <- function(b, id, label, required = FALSE) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "INPUT"); b <- dl_kv(b, "key", dl_key(b, "i"))
  b <- dl_kv(b, "id", id); b <- dl_kv(b, "label", label)
  if (required) b <- dl_kvbool(b, "required")
  b <- dl_co(b); b
}
dl_textarea <- function(b, id, label, rows = 3) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "TEXTAREA"); b <- dl_kv(b, "key", dl_key(b, "ta"))
  b <- dl_kv(b, "id", id); b <- dl_kv(b, "label", label)
  if (rows > 0) b <- dl_kvint(b, "rows", rows)
  b <- dl_co(b); b
}
dl_checkbox <- function(b, id, label) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "CHECKBOX"); b <- dl_kv(b, "key", dl_key(b, "cb"))
  b <- dl_kv(b, "id", id); b <- dl_kv(b, "label", label); b <- dl_co(b); b
}
dl_rating <- function(b, id, label) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "RATING"); b <- dl_kv(b, "key", dl_key(b, "rt"))
  b <- dl_kv(b, "id", id); b <- dl_kv(b, "label", label); b <- dl_co(b); b
}

dl_button <- function(b, id, title, color = "primary", is_default = FALSE) {
  b <- dl_obj(b); b <- dl_kv(b, "type", "BUTTON"); b <- dl_kv(b, "key", dl_key(b, "btn"))
  b <- dl_kv(b, "id", id); b <- dl_kv(b, "title", title); b <- dl_kv(b, "color", color)
  if (is_default) b <- dl_kvbool(b, "default")
  b <- dl_co(b); b
}

dl_section <- function(b, title, text) {
  b <- dl_fieldset(b, title); b <- dl_label(b, text); b <- dl_end_fieldset(b); b
}
