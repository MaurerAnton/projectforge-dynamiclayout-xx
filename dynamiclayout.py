"""
DynamicLayout Python builder — generate PFDL JSON from Python code.

Single-file library. Zero dependencies outside the standard library.
Works on Python 3.8+.

Example:
    from dynamiclayout import Layout

    page = Layout('My Page')
    page.fieldset('Info').label('Hello from Python!').end()
    page.button('ok', 'OK', 'primary', default=True)
    print(page.json())
"""

from __future__ import annotations
import json
from typing import Any, Optional

# ── Types ──────────────────────────────────────────────────────────

class SelectValue:
    """Dropdown/radio option."""
    def __init__(self, id: Any, display_name: str, order: int = 0):
        self.id = id
        self.display_name = display_name
        self.order = order

    def to_dict(self) -> dict:
        d = {'id': self.id, 'displayName': self.display_name}
        if self.order: d['order'] = self.order
        return d

class Badge:
    """Badge/chip."""
    def __init__(self, title: str, color: str = '', pill: bool = False):
        self.title = title
        self.color = color
        self.pill = pill

    def to_dict(self) -> dict:
        d = {'title': self.title}
        if self.color: d['color'] = self.color
        if self.pill: d['pill'] = True
        return d

class Length:
    """Bootstrap grid column widths (1-12)."""
    def __init__(self, xs: int = 0, sm: int = 0, md: int = 0, lg: int = 0, xl: int = 0):
        self.xs = xs; self.sm = sm; self.md = md; self.lg = lg; self.xl = xl

    def to_dict(self) -> dict:
        d = {}
        if self.xs: d['xs'] = self.xs
        if self.sm: d['sm'] = self.sm
        if self.md: d['md'] = self.md
        if self.lg: d['lg'] = self.lg
        if self.xl: d['xl'] = self.xl
        return d if d else {}

class ResponseAction:
    """Server action after button click."""
    def __init__(self, action_type: str, url: str = '', method: str = '',
                 target_type: str = '', target_url: str = '',
                 message: str = '', color: str = ''):
        self.type = action_type
        self.url = url
        self.method = method
        self.target_type = target_type
        self.target_url = target_url
        self.message = message
        self.color = color

    def to_dict(self) -> dict:
        d = {'type': self.type}
        for k in ('url', 'method', 'targetType', 'targetUrl', 'message', 'color'):
            v = getattr(self, {'targetType': 'target_type', 'targetUrl': 'target_url'}.get(k, k), '')
            if v: d[k] = v
        return d

# ── Constants ──────────────────────────────────────────────────────

# Colors
PRIMARY   = 'primary'
SECONDARY = 'secondary'
SUCCESS   = 'success'
DANGER    = 'danger'
WARNING   = 'warning'
INFO      = 'info'
LIGHT     = 'light'
DARK      = 'dark'
LINK      = 'link'

# Data types
STRING     = 'STRING'
INTEGER    = 'INTEGER'
LONG       = 'LONG'
BIG_DECIMAL = 'BIG_DECIMAL'
DATE       = 'DATE'
TIME       = 'TIME'
TIMESTAMP  = 'TIMESTAMP'
BOOLEAN    = 'BOOLEAN'
PASSWORD   = 'PASSWORD'

# ── Builder ────────────────────────────────────────────────────────

class Layout:
    """Fluent builder for DynamicLayout JSON."""

    _key_counter = 0

    def __init__(self, title: str, uid: str = ''):
        self._title = title
        self._uid = uid or f'layout_{id(self)}'
        self._layout: list[dict] = []
        self._actions: list[dict] = []
        self._stack: list[list[dict]] = [self._layout]

    def _key(self, prefix: str) -> str:
        Layout._key_counter += 1
        return f'{prefix}_{Layout._key_counter}'

    def _top(self) -> list[dict]:
        return self._stack[-1]

    def _add(self, el: dict) -> 'Layout':
        self._top().append(el)
        return self

    def _push(self, el: dict) -> 'Layout':
        self._add(el)
        el['content'] = []
        self._stack.append(el['content'])
        return self

    def _pop(self) -> 'Layout':
        self._stack.pop()
        return self

    # ── Containers ──

    def fieldset(self, title: str, collapsed: bool | None = None) -> 'Layout':
        el = {'type': 'FIELDSET', 'key': self._key('fs'), 'title': title}
        if collapsed is not None: el['collapsed'] = collapsed
        return self._push(el)

    def end(self) -> 'Layout': return self._pop()

    def row(self) -> 'Layout':
        return self._push({'type': 'ROW', 'key': self._key('r')})

    def end_row(self) -> 'Layout': return self._pop()

    def col(self, *sizes: int) -> 'Layout':
        """col(xs, sm=0, md=0, lg=0, xl=0)"""
        el = {'type': 'COL', 'key': self._key('c')}
        length = Length(*sizes)
        if length.to_dict(): el['length'] = length.to_dict()
        return self._push(el)

    def end_col(self) -> 'Layout': return self._pop()

    def group(self) -> 'Layout':
        return self._push({'type': 'GROUP', 'key': self._key('g')})

    def inline(self) -> 'Layout':
        return self._push({'type': 'INLINE_GROUP', 'key': self._key('ig')})

    # ── Display ──

    def label(self, text: str) -> 'Layout':
        return self._add({'type': 'LABEL', 'key': self._key('l'), 'label': text})

    def alert(self, message: str, color: str = INFO) -> 'Layout':
        return self._add({'type': 'ALERT', 'key': self._key('a'), 'message': message, 'color': color})

    def badge(self, title: str, color: str = PRIMARY) -> 'Layout':
        el = {'type': 'BADGE', 'key': self._key('bd'), 'title': title}
        if color: el['color'] = color
        return self._add(el)

    def progress(self, pct: int, label: str = '', color: str = '') -> 'Layout':
        el = {'type': 'PROGRESS', 'key': self._key('pr'), 'progress': pct}
        if label: el['label'] = label
        if color: el['color'] = color
        return self._add(el)

    def spacer(self, height_px: int = 20) -> 'Layout':
        return self._add({'type': 'SPACER', 'key': self._key('sp'), 'width': height_px})

    # ── Inputs ──

    def input(self, id: str, label: str = '', *,
              required: bool = False, data_type: str = 'STRING',
              max_length: int = 0, focus: bool = False,
              color: str = '', pattern: str = '',
              autocomplete: str = '', tooltip: str = '',
              additional_label: str = '') -> 'Layout':
        el = {'type': 'INPUT', 'key': self._key('i'), 'id': id, 'label': label}
        if data_type != STRING: el['dataType'] = data_type
        if required: el['required'] = True
        if max_length: el['maxLength'] = max_length
        if focus: el['focus'] = True
        if color: el['color'] = color
        if pattern: el['pattern'] = pattern
        if autocomplete: el['autoComplete'] = autocomplete
        if tooltip: el['tooltip'] = tooltip
        if additional_label: el['additionalLabel'] = additional_label
        return self._add(el)

    def textarea(self, id: str, label: str = '', rows: int = 3) -> 'Layout':
        return self._add({'type': 'TEXTAREA', 'key': self._key('ta'), 'id': id, 'label': label, 'rows': rows})

    def checkbox(self, id: str, label: str = '') -> 'Layout':
        return self._add({'type': 'CHECKBOX', 'key': self._key('cb'), 'id': id, 'label': label})

    def select(self, id: str, label: str, values: list[SelectValue]) -> 'Layout':
        return self._add({
            'type': 'SELECT', 'key': self._key('s'), 'id': id, 'label': label,
            'values': [v.to_dict() for v in values]
        })

    def select_pairs(self, id: str, label: str, pairs: list[tuple]) -> 'Layout':
        return self.select(id, label, [SelectValue(p[0], p[1]) for p in pairs])

    def radio(self, id: str, label: str, values: list[SelectValue]) -> 'Layout':
        return self._add({
            'type': 'RADIOBUTTON', 'key': self._key('rb'), 'id': id, 'label': label,
            'values': [v.to_dict() for v in values]
        })

    def rating(self, id: str, label: str = '') -> 'Layout':
        return self._add({'type': 'RATING', 'key': self._key('rt'), 'id': id, 'label': label})

    def readonly(self, id: str, label: str = '') -> 'Layout':
        return self._add({'type': 'READONLY_FIELD', 'key': self._key('ro'), 'id': id, 'label': label})

    def editor(self, id: str, label: str = '', rows: int = 15) -> 'Layout':
        return self._add({'type': 'EDITOR', 'key': self._key('ed'), 'id': id, 'label': label, 'rows': rows})

    # ── Files ──

    def attachments(self, id: str, label: str = '') -> 'Layout':
        return self._add({'type': 'ATTACHMENT_LIST', 'key': self._key('al'), 'id': id, 'label': label})

    def droparea(self, id: str, label: str = '', accept: str = '', multiple: bool = False) -> 'Layout':
        el = {'type': 'DROP_AREA', 'key': self._key('da'), 'id': id, 'label': label}
        if accept: el['accept'] = accept
        if multiple: el['multiple'] = True
        return self._add(el)

    # ── Tables ──

    def aggrid(self, table_id: str, columns: list[dict]) -> 'Layout':
        return self._add({'type': 'AG_GRID', 'key': self._key('ag'), 'id': table_id, 'columnDefs': columns})

    def aggrid_col(self, id: str, header: str, **kwargs) -> dict:
        col = {'type': 'AG_GRID_COLUMN_DEF', 'key': self._key('agc'), 'id': id, 'headerName': header}
        col.update(kwargs)
        return col

    # ── Actions ──

    def button(self, id: str, title: str, color: str = PRIMARY, *,
               default: bool = False, icon: str = '',
               response_action: ResponseAction | dict | None = None) -> 'Layout':
        el: dict = {'type': 'BUTTON', 'key': self._key('btn'), 'id': id, 'title': title, 'color': color}
        if default: el['default'] = True
        if icon: el['icon'] = icon
        if response_action:
            if isinstance(response_action, ResponseAction):
                el['responseAction'] = response_action.to_dict()
            else:
                el['responseAction'] = response_action
        self._actions.append(el)
        return self

    # ── Output ──

    def to_dict(self) -> dict:
        while len(self._stack) > 1:
            self._pop()
        return {
            'ui': {
                'title': self._title,
                'uid': self._uid,
                'layout': self._layout,
                'actions': self._actions,
                'translations': {},
                'userAccess': {'cancel': True},
            }
        }

    def json(self, indent: int = 2) -> str:
        return json.dumps(self.to_dict(), indent=indent, ensure_ascii=False)

    def __str__(self) -> str:
        return self.json()

    # ── Shortcuts ──

    def section(self, fieldset_title: str, text: str) -> 'Layout':
        return self.fieldset(fieldset_title).label(text).end()

    def feedback_form(self) -> 'Layout':
        """Pre-built feedback form: name, email, message, Send."""
        return (self.fieldset('Your Details')
            .input('name', 'Name', required=True)
            .input('email', 'Email', required=True)
            .textarea('message', 'Message', 5)
            .end()
            .button('send', 'Send', PRIMARY, default=True)
            .button('cancel', 'Cancel', SECONDARY))
