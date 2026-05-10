/*
 * DynamicLayout C89/ANSI C API — generate layout JSON from strict C89 code.
 *
 * Single-header. Compatible with any C89 compiler (gcc -std=c89 -pedantic).
 * No // comments, no mixed declarations, no inline, no long long.
 *
 * Example:
 *   char buf[8192];
 *   DL b = dl_begin(buf, sizeof(buf), "My Page");
 *   dl_fieldset(&b, "Info");
 *   dl_label(&b, "Hello from C89!");
 *   dl_end_fieldset(&b);
 *   dl_button(&b, "ok", "OK", "primary", 1);
 *   dl_end(&b);
 *   puts(buf);
 */

#ifndef DYNAMICLAYOUT_C89_H
#define DYNAMICLAYOUT_C89_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    char *buf;
    size_t size;
    size_t pos;
    int depth;
    int comma;
    int key_counter;
} DL;

static void dlc(DL *b, char c) { if (b->pos < b->size - 1) b->buf[b->pos++] = c; }
static void dls(DL *b, const char *s) { while (*s && b->pos < b->size - 1) b->buf[b->pos++] = *s++; }
static void dl_indent(DL *b) { int i; dlc(b, '\n'); for (i = 0; i < b->depth; i++) dls(b, "  "); }
static void dl_cm(DL *b) { if (b->comma) dlc(b, ','); b->comma = 0; }

static void dl_escape(DL *b, const char *s) {
    dlc(b, '"');
    while (*s) {
        switch (*s) {
            case '"':  dls(b, "\\\""); break;
            case '\\': dls(b, "\\\\"); break;
            case '\n': dls(b, "\\n");  break;
            case '\r': dls(b, "\\r");  break;
            case '\t': dls(b, "\\t");  break;
            default:   dlc(b, *s);     break;
        }
        s++;
    }
    dlc(b, '"');
}

static void dl_kv(DL *b, const char *key, const char *val) {
    if (!val) return;
    dl_cm(b); dlc(b, ','); dl_indent(b);
    dl_escape(b, key); dls(b, ": "); dl_escape(b, val);
    b->comma = 1;
}

static void dl_kvint(DL *b, const char *key, int val) {
    char tmp[16];
    sprintf(tmp, "%d", val);
    dl_cm(b); dlc(b, ','); dl_indent(b);
    dl_escape(b, key); dls(b, ": "); dls(b, tmp);
    b->comma = 1;
}

static void dl_kvbool(DL *b, const char *key) {
    dl_cm(b); dlc(b, ','); dl_indent(b);
    dl_escape(b, key); dls(b, ": true");
    b->comma = 1;
}

static void dl_obj(DL *b) { dl_cm(b); dlc(b, ','); dl_indent(b); dlc(b, '{'); b->depth++; b->comma = 0; }
static void dl_close_obj(DL *b) { b->depth--; dl_indent(b); dlc(b, '}'); b->comma = 1; }
static void dl_arr(DL *b, const char *key) { dl_cm(b); dlc(b, ','); dl_indent(b); dl_escape(b, key); dls(b, ": ["); b->depth++; b->comma = 0; }
static void dl_close_arr(DL *b) { b->depth--; dl_indent(b); dlc(b, ']'); b->comma = 1; }

static const char* dl_key(DL *b, const char *prefix) {
    static char buf[32];
    b->key_counter++;
    sprintf(buf, "%s_%d", prefix, b->key_counter);
    return buf;
}

/* Public API */

static DL dl_begin(char *buffer, size_t size, const char *title) {
    DL b;
    b.buf = buffer; b.size = size; b.pos = 0; b.depth = 0; b.comma = 0; b.key_counter = 0;
    dls(&b, "{\"ui\":{");
    b.depth = 2; b.comma = 0;
    dl_kv(&b, "title", title);
    dl_arr(&b, "layout");
    return b;
}

static void dl_end(DL *b) {
    dl_close_arr(b);
    b->comma = 0; dlc(b, ',');
    dls(b, "\"translations\":{},");
    dls(b, "\"userAccess\":{\"cancel\":true}");
    dls(b, "}}");
    b->buf[b->pos] = '\0';
}

/* Containers */
static void dl_fieldset(DL *b, const char *title) {
    dl_obj(b); dl_kv(b, "type", "FIELDSET"); dl_kv(b, "key", dl_key(b, "fs"));
    dl_kv(b, "title", title); dl_arr(b, "content");
}
static void dl_end_fieldset(DL *b) { dl_close_arr(b); dl_close_obj(b); }

static void dl_row(DL *b) { dl_obj(b); dl_kv(b, "type", "ROW"); dl_kv(b, "key", dl_key(b, "r")); dl_arr(b, "content"); }
static void dl_end_row(DL *b) { dl_close_arr(b); dl_close_obj(b); }

static void dl_col(DL *b, int xs, int md) {
    dl_obj(b); dl_kv(b, "type", "COL"); dl_kv(b, "key", dl_key(b, "c"));
    if (xs || md) { char txs[8], tmd[8];
        dl_cm(b); dlc(b, ','); dl_indent(b); dls(b, "\"length\":{");
        if (xs) { sprintf(txs, "%d", xs); dls(b, "\"xs\":"); dls(b, txs); if (md) dlc(b, ','); }
        if (md) { sprintf(tmd, "%d", md); dls(b, "\"md\":"); dls(b, tmd); }
        dls(b, "}"); b->comma = 1;
    }
    dl_arr(b, "content");
}
static void dl_end_col(DL *b) { dl_close_arr(b); dl_close_obj(b); }

/* Display */
static void dl_label(DL *b, const char *text) {
    dl_obj(b); dl_kv(b, "type", "LABEL"); dl_kv(b, "key", dl_key(b, "l")); dl_kv(b, "label", text); dl_close_obj(b);
}
static void dl_alert(DL *b, const char *msg, const char *color) {
    dl_obj(b); dl_kv(b, "type", "ALERT"); dl_kv(b, "key", dl_key(b, "a")); dl_kv(b, "message", msg); dl_kv(b, "color", color); dl_close_obj(b);
}
static void dl_badge(DL *b, const char *title, const char *color) {
    dl_obj(b); dl_kv(b, "type", "BADGE"); dl_kv(b, "key", dl_key(b, "bd")); dl_kv(b, "title", title); dl_kv(b, "color", color); dl_close_obj(b);
}
static void dl_spacer(DL *b, int px) {
    dl_obj(b); dl_kv(b, "type", "SPACER"); dl_kv(b, "key", dl_key(b, "sp")); dl_kvint(b, "width", px); dl_close_obj(b);
}

/* Inputs */
static void dl_input(DL *b, const char *id, const char *label, int required) {
    dl_obj(b); dl_kv(b, "type", "INPUT"); dl_kv(b, "key", dl_key(b, "i")); dl_kv(b, "id", id); dl_kv(b, "label", label);
    if (required) dl_kvbool(b, "required"); dl_close_obj(b);
}
static void dl_textarea(DL *b, const char *id, const char *label, int rows) {
    dl_obj(b); dl_kv(b, "type", "TEXTAREA"); dl_kv(b, "key", dl_key(b, "ta")); dl_kv(b, "id", id); dl_kv(b, "label", label);
    if (rows > 0) dl_kvint(b, "rows", rows); dl_close_obj(b);
}
static void dl_checkbox(DL *b, const char *id, const char *label) {
    dl_obj(b); dl_kv(b, "type", "CHECKBOX"); dl_kv(b, "key", dl_key(b, "cb")); dl_kv(b, "id", id); dl_kv(b, "label", label); dl_close_obj(b);
}
static void dl_rating(DL *b, const char *id, const char *label) {
    dl_obj(b); dl_kv(b, "type", "RATING"); dl_kv(b, "key", dl_key(b, "rt")); dl_kv(b, "id", id); dl_kv(b, "label", label); dl_close_obj(b);
}

/* Actions */
static void dl_button(DL *b, const char *id, const char *title, const char *color, int is_default) {
    dl_obj(b); dl_kv(b, "type", "BUTTON"); dl_kv(b, "key", dl_key(b, "btn")); dl_kv(b, "id", id); dl_kv(b, "title", title); dl_kv(b, "color", color);
    if (is_default) dl_kvbool(b, "default"); dl_close_obj(b);
}

/* Shortcuts */
static void dl_section(DL *b, const char *title, const char *text) {
    dl_fieldset(b, title); dl_label(b, text); dl_end_fieldset(b);
}

#ifdef __cplusplus
}
#endif

#endif
