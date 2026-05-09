#ifndef DYNAMICLAYOUT_H
#define DYNAMICLAYOUT_H

/*
 * DynamicLayout C API — generate layout JSON from C/C++.
 *
 * Single-header library. Include once, use anywhere.
 * Requires: C99 or C++98.
 *
 * Example:
 *   char buf[8192];
 *   DL b = dl_begin(buf, sizeof(buf), "My Page");
 *   dl_fieldset(&b, "Info");
 *   dl_label(&b, "Hello from C!");
 *   dl_end_fieldset(&b);
 *   dl_end(&b);
 *   puts(buf);
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

/* === State === */
typedef struct {
    char *buf;
    size_t size;
    size_t pos;
    int depth;
    int comma;
} DL;

/* === Internal helpers === */
static void dlc(DL *b, char c) { if (b->pos < b->size - 1) b->buf[b->pos++] = c; }
static void dls(DL *b, const char *s) { while (*s && b->pos < b->size - 1) b->buf[b->pos++] = *s++; }

static void dl_indent(DL *b) {
    dlc(b, '\n');
    for (int i = 0; i < b->depth; i++) dls(b, "  ");
}

static void dl_cm(DL *b) { if (b->comma) dlc(b, ','); b->comma = 0; }
static void dl_cma(DL *b) { dlc(b, ','); }

static void dl_escape(DL *b, const char *s) {
    dlc(b, '"');
    while (*s) {
        switch (*s) {
            case '"': dls(b, "\\\""); break;
            case '\\': dls(b, "\\\\"); break;
            case '\n': dls(b, "\\n"); break;
            case '\r': dls(b, "\\r"); break;
            case '\t': dls(b, "\\t"); break;
            default: dlc(b, *s); break;
        }
        s++;
    }
    dlc(b, '"');
}

/* Write key-value pair (string value) */
static void dl_kv(DL *b, const char *key, const char *val) {
    if (!val) return;
    if (b->comma) { dlc(b, ','); b->comma = 0; }
    dl_indent(b);
    dl_escape(b, key); dls(b, ": "); dl_escape(b, val);
    b->comma = 1;
}

static void dl_kv_bool(DL *b, const char *key) {
    dl_cm(b); dl_cma(b); dl_indent(b);
    dl_escape(b, key); dls(b, ": true");
    b->comma = 1;
}

/* Write key and open array/object */
static void dl_arr(DL *b, const char *key) {
    if (b->comma) { dlc(b, ','); b->comma = 0; }
    dl_indent(b);
    dl_escape(b, key); dls(b, ": [");
    b->depth++; b->comma = 0;
}

static void dl_obj(DL *b) {
    if (b->comma) { dlc(b, ','); b->comma = 0; }
    dl_indent(b);
    dlc(b, '{'); b->depth++; b->comma = 0;
}

static void dl_close_arr(DL *b) {
    b->depth--; dl_indent(b); dlc(b, ']'); b->comma = 1;
}

static void dl_close_obj(DL *b) {
    b->depth--; dl_indent(b); dlc(b, '}'); b->comma = 1;
}

/* Write a list of string values (for SELECT options) */
static void dl_values(DL *b, const char *const *ids, const char *const *labels, int count) {
    dl_arr(b, "values");
    for (int i = 0; i < count; i++) {
        dl_obj(b);
        dl_kv(b, "id", ids[i]);
        dl_kv(b, "displayName", labels[i]);
        dl_close_obj(b);
    }
    dl_close_arr(b);
}

/* === BEGIN: Public API === */

/* Start a new layout. Returns builder state. */
static DL dl_begin(char *buffer, size_t size, const char *title) {
    DL b = { buffer, size, 0, 0, 0 };
    dls(&b, "{\"ui\":{");
    b.depth = 2; b.comma = 0;
    dl_kv(&b, "title", title);
    dl_arr(&b, "layout");
    return b;
}

/* Finish the layout. Closes all open structures. */
static void dl_end(DL *b) {
    dl_close_arr(b);                         /* ] close layout array */
    b->comma = 0; dls(b, ",");
    dls(b, "\"translations\":{},");
    dls(b, "\"userAccess\":{\"cancel\":true}");
    dls(b, "}}");                           /* close ui + root */
    dlc(b, '\n'); b->buf[b->pos] = 0;
}

/* === Fieldset (container) === */
static void dl_fieldset(DL *b, const char *title) {
    dl_obj(b);
    dl_kv(b, "type", "FIELDSET");
    dl_kv(b, "key", "fs");
    dl_kv(b, "title", title);
    dl_arr(b, "content");
}

static void dl_end_fieldset(DL *b) {
    dl_close_arr(b);    /* ] content */
    dl_close_obj(b);    /* } fieldset */
}

/* === ROW (flex row) === */
static void dl_row(DL *b) {
    dl_obj(b);
    dl_kv(b, "type", "ROW");
    dl_kv(b, "key", "row");
    dl_arr(b, "content");
}

static void dl_end_row(DL *b) {
    dl_close_arr(b);
    dl_close_obj(b);
}

/* === COL (flex column) === */
static void dl_col(DL *b, int xs, int md) {
    dl_obj(b);
    dl_kv(b, "type", "COL");
    dl_kv(b, "key", "col");
    /* Length object */
    dl_cm(b); dl_cma(b); dl_indent(b);
    dls(b, "\"length\":{");
    if (xs) { dls(b, "\"xs\":"); char tmp[8]; snprintf(tmp,8,"%d",xs); dls(b, tmp); dl_cma(b); }
    if (md) { dls(b, "\"md\":"); char tmp[8]; snprintf(tmp,8,"%d",md); dls(b, tmp); }
    dls(b, "}");
    b->comma = 1;
    dl_arr(b, "content");
}

static void dl_end_col(DL *b) {
    dl_close_arr(b);
    dl_close_obj(b);
}

/* === LABEL === */
static void dl_label(DL *b, const char *text) {
    dl_obj(b);
    dl_kv(b, "type", "LABEL");
    dl_kv(b, "key", "lbl");
    dl_kv(b, "label", text);
    dl_close_obj(b);
}

/* === INPUT === */
static void dl_input(DL *b, const char *id, const char *label) {
    dl_obj(b);
    dl_kv(b, "type", "INPUT");
    dl_kv(b, "key", "inp");
    dl_kv(b, "id", id);
    dl_kv(b, "label", label);
    dl_close_obj(b);
}

/* === TEXTAREA === */
static void dl_textarea(DL *b, const char *id, const char *label, int rows) {
    dl_obj(b);
    dl_kv(b, "type", "TEXTAREA");
    dl_kv(b, "key", "ta");
    dl_kv(b, "id", id);
    dl_kv(b, "label", label);
    if (rows) { char tmp[8]; snprintf(tmp,8,"%d",rows); dl_kv(b, "rows", tmp); }
    dl_close_obj(b);
}

/* === CHECKBOX === */
static void dl_checkbox(DL *b, const char *id, const char *label) {
    dl_obj(b);
    dl_kv(b, "type", "CHECKBOX");
    dl_kv(b, "key", "cb");
    dl_kv(b, "id", id);
    dl_kv(b, "label", label);
    dl_close_obj(b);
}

/* === SELECT (dropdown) === */
static void dl_select(DL *b, const char *id, const char *label,
                       const char *const *ids, const char *const *labels, int count) {
    dl_obj(b);
    dl_kv(b, "type", "SELECT");
    dl_kv(b, "key", "sel");
    dl_kv(b, "id", id);
    dl_kv(b, "label", label);
    dl_values(b, ids, labels, count);
    dl_close_obj(b);
}

/* === BUTTON === */
static void dl_button(DL *b, const char *id, const char *title, const char *color) {
    dl_obj(b);
    dl_kv(b, "type", "BUTTON");
    dl_kv(b, "key", "btn");
    dl_kv(b, "id", id);
    dl_kv(b, "title", title);
    dl_kv(b, "color", color);
    dl_close_obj(b);
}

/* === Actions (buttons at bottom) === */
static void dl_actions(DL *b) {
    dl_arr(b, "actions");
}

static void dl_end_actions(DL *b) {
    dl_close_arr(b);
}

/* === ALERT === */
static void dl_alert(DL *b, const char *message, const char *color) {
    dl_obj(b);
    dl_kv(b, "type", "ALERT");
    dl_kv(b, "key", "alert");
    dl_kv(b, "message", message);
    dl_kv(b, "color", color);
    dl_close_obj(b);
}

/* === BADGE === */
static void dl_badge(DL *b, const char *title, const char *color) {
    dl_obj(b);
    dl_kv(b, "type", "BADGE");
    dl_kv(b, "key", "bdg");
    dl_kv(b, "title", title);
    dl_kv(b, "color", color);
    dl_close_obj(b);
}

/* Quick helper: add a fieldset with one label */
static void dl_section(DL *b, const char *title, const char *text) {
    dl_fieldset(b, title);
    dl_label(b, text);
    dl_end_fieldset(b);
}

/* Quick helper: add a feedback form */
static void dl_feedback_form(DL *b) {
    dl_fieldset(b, "Your Details");
    dl_input(b, "name", "Name");
    dl_input(b, "email", "Email");
    dl_textarea(b, "message", "Message", 5);
    dl_end_fieldset(b);
    dl_actions(b);
    dl_button(b, "send", "Send", "primary");
    dl_button(b, "cancel", "Cancel", "secondary");
    dl_end_actions(b);
}

#ifdef __cplusplus
}
#endif

#endif /* DYNAMICLAYOUT_H */
