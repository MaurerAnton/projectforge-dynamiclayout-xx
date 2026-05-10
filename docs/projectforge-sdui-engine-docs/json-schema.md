# JSON Schema for DynamicLayout

> **Status:** Available. The formal JSON Schema is at [`dynamiclayout-schema.json`](https://github.com/MaurerAnton/projectforge-dynamiclayout/blob/master/dynamiclayout-schema.json) (Draft 2020-12). Use it to validate layouts in any language, auto-generate types, or implement a client without reading source code.

## Schema source

| File | Description |
|------|-------------|
| [`dynamiclayout-schema.json`](https://github.com/MaurerAnton/projectforge-dynamiclayout/blob/master/dynamiclayout-schema.json) | Formal JSON Schema (Draft 2020-12). Covers all 30+ component types. |
| [`api-reference.md`](api-reference.md) | Human-readable reference with Kotlin/React mapping. |
| [`playground/index.html`](https://raw.githack.com/MaurerAnton/projectforge-dynamiclayout/master/playground/index.html) | Live playground — paste JSON to see it render. |

## Structure

```
FormLayoutData
├── data: object                    Entity data (key → value)
├── ui: UILayout
│   ├── title: string               Page title
│   ├── uid: string                 Unique layout identifier
│   ├── layout: UIElement[]         Main content
│   ├── actions: UIButton[]         Action buttons
│   ├── layoutBelowActions: UIElement[]   Content below action bar
│   ├── pageMenu: UIPageMenu        List page menu
│   ├── namedContainers: UINamedContainer[]  Filter containers
│   ├── translations: object        i18n key → translated text
│   ├── userAccess: UserAccess      Permission flags
│   ├── showHistory: boolean        History sidebar toggle
│   └── watchFields: string[]       Field IDs triggering server round‑trip
├── serverData: object              Arbitrary server metadata
└── variables: object               Client-side state
```

**UIElement** — 33 types, always including `type` (UIElementType) and `key` (unique string):

| Type | Category | Has `id` | Has `content[]` |
|------|----------|:--------:|:---------------:|
| `ROW` | Container | | ✅ |
| `COL` | Container | | ✅ |
| `FIELDSET` | Container | | ✅ |
| `GROUP` | Container | | ✅ |
| `INLINE_GROUP` | Container | | ✅ |
| `FRAGMENT` | Container | | ✅ |
| `NAMED_CONTAINER` | Container | ✅ | ✅ |
| `LIST` | Container | ✅ | ✅ |
| `LABEL` | Display | | |
| `INPUT` | Input | ✅ | |
| `TEXTAREA` | Input | ✅ | |
| `CHECKBOX` | Input | ✅ | |
| `SELECT` | Input | ✅ | |
| `CREATABLE_SELECT` | Input | ✅ | |
| `RADIOBUTTON` | Input | ✅ | |
| `RATING` | Input | ✅ | |
| `READONLY_FIELD` | Display | ✅ | |
| `BUTTON` | Action | ✅ | |
| `ALERT` | Display | | |
| `BADGE` | Display | | |
| `BADGE_LIST` | Display | | |
| `PROGRESS` | Display | | |
| `SPACER` | Layout | | |
| `EDITOR` | Input | ✅ | |
| `TABLE` | Table | | ✅ (columns) |
| `TABLE_COLUMN` | Table (aux) | ✅ | |
| `TABLE_LIST_PAGE` | Table | | |
| `AG_GRID` | Table | | ✅ (columnDefs) |
| `AG_GRID_LIST_PAGE` | Table | | ✅ (columnDefs) |
| `AG_GRID_COLUMN_DEF` | Table (aux) | ✅ | |
| `ATTACHMENT_LIST` | File | | |
| `DROP_AREA` | File | | |
| `CUSTOMIZED` | Custom | ✅ | |
| `FILTER_ELEMENT` | Filter | ✅ | |

## Minimal valid JSON

```json
{
  "ui": {
    "title": "Hello",
    "uid": "layout1",
    "layout": [
      { "type": "LABEL", "key": "el-1", "label": "Hello World" }
    ]
  }
}
```

> **Playground:** Paste the minimal JSON above into the playground. You'll see "Hello World" rendered. Add `"type": "INPUT", "key": "el-2", "id": "name", "label": "Name"` to see an input field appear.

## Full example — edit form

```json
{
  "data": { "firstName": "John", "lastName": "Doe", "email": "john@example.com" },
  "ui": {
    "title": "user.edit",
    "uid": "layout1234567890",
    "layout": [
      {
        "type": "FIELDSET",
        "key": "el-1",
        "title": "Personal Data",
        "collapsed": false,
        "content": [
          { "type": "ROW", "key": "el-2", "content": [
            { "type": "COL", "key": "el-3", "length": { "md": 6 }, "content": [
              { "type": "INPUT", "key": "el-4", "id": "firstName", "label": "First Name", "required": true }
            ]},
            { "type": "COL", "key": "el-5", "length": { "md": 6 }, "content": [
              { "type": "INPUT", "key": "el-6", "id": "lastName", "label": "Last Name", "required": true }
            ]}
          ]},
          { "type": "INPUT", "key": "el-7", "id": "email", "label": "E‑mail", "required": true, "maxLength": 255 },
          { "type": "SELECT", "key": "el-8", "id": "country", "label": "Country", "values": [
            { "id": "DE", "displayName": "Germany" },
            { "id": "US", "displayName": "United States" }
          ]}
        ]
      }
    ],
    "actions": [
      { "type": "BUTTON", "key": "el-9", "id": "save", "title": "Save", "color": "primary", "responseAction": { "type": "SAVE", "url": "/rs/user/save", "method": "POST", "targetType": "UPDATE_DATA" } },
      { "type": "BUTTON", "key": "el-10", "id": "cancel", "title": "Cancel", "color": "secondary", "responseAction": { "type": "CUSTOM", "targetType": "REDIRECT", "targetUrl": "/react/user/list" } }
    ],
    "translations": { "save": "Save", "cancel": "Cancel" },
    "userAccess": { "insert": true, "update": true, "delete": true, "cancel": true }
  }
}
```

## Usage — validating layouts

### JavaScript / TypeScript (AJV)

```js
import Ajv from 'ajv';
import schema from './dynamiclayout-schema.json' with { type: 'json' };

const ajv = new Ajv();
const validate = ajv.compile(schema);

const layout = { ui: { title: "Test", uid: "1", layout: [
  { type: "LABEL", key: "l", label: "Hi" }
]}};

if (!validate(layout)) {
    console.error('Invalid layout:', validate.errors);
    // e.g. [{ instancePath: '/ui/layout/0', keyword: 'required',
    //        params: { missingProperty: 'key' }, message: "must have required property 'key'" }]
}
```

### Python (jsonschema)

```python
import json
import jsonschema

with open('dynamiclayout-schema.json') as f:
    schema = json.load(f)

layout = {
    "ui": {
        "title": "Test", "uid": "1",
        "layout": [{"type": "LABEL", "key": "l1", "label": "Hi"}]
    }
}

jsonschema.validate(layout, schema)  # raises ValidationError if invalid
```

### Go (santhosh-tekuri/jsonschema)

```go
import "github.com/santhosh-tekuri/jsonschema/v5"

func validateDynamicLayout(jsonData []byte) error {
    sch, _ := jsonschema.Compile("dynamiclayout-schema.json")
    var v interface{}
    json.Unmarshal(jsonData, &v)
    return sch.Validate(v)
}
```

### Kotlin (NetworkNT)

```kotlin
val schema = JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V202012)
    .getSchema(javaClass.getResourceAsStream("/dynamiclayout-schema.json"))
val report = schema.validate(layoutJson)
if (!report.isSuccess) {
    report.forEach { println("${it.instanceLocation}: ${it.message}") }
}
```

### C (`dynamiclayout.h` — built-in correctness)

The C API generates valid JSON by construction. You cannot produce invalid JSON with `dl_*()` calls — no validation step needed.

> **Playground:** The playground validates JSON in real-time. Unknown `type` values render as red error spans. Paste invalid JSON (e.g. missing `key`) to see the error bar.

## Validation guarantees

The JSON Schema covers:

- **Structural correctness** — `type` must be a known value, `key` must be present, containers must have `content[]`.
- **Type-specific fields** — e.g. `INPUT` requires `id`, `SELECT` requires `values[]`, `FIELDSET` allows `collapsed`.
- **Enum values** — `color` limited to 9 Bootstrap colors, `dataType` to known `UIDataType` values.
- **Numeric ranges** — `UILength` columns 1–12, `PROGRESS` 0–100.

The schema does **not** cover (by design):
- i18n key semantics (whether a string starts with `'` for literal text)
- Business logic constraints (e.g. "save button must have a responseAction")
- Cross-field validation (e.g. "if focus=true, dataType must not be READONLY")

## How this enables "Any" server language

With the JSON Schema, any language can:

1. **Validate** layouts before sending them to the client — `pip install jsonschema && python validate.py`
2. **Generate** layouts programmatically — write a builder DSL in your language (300 lines, same pattern as `dynamiclayout.h`)
3. **Type-check** — generate TypeScript types or Python dataclasses from the schema

This is why RJSF and DivKit claim "Any server language" — they have published JSON Schemas. PFDL now has one too. Combine with `dynamiclayout.h` (C) and `JsLayout` (JS) as reference implementations, and any language can participate.

## Related

| Document | Purpose |
|----------|---------|
| [api-reference.md](api-reference.md) | Full UI component reference (1157 lines) |
| [architecture.md](architecture.md) | Architecture, layers, data flow |
| [comparison.md](comparison.md) | Comparison with competitors |
| [`dynamiclayout.h`](https://github.com/MaurerAnton/projectforge-dynamiclayout/blob/master/dynamiclayout.h) | C API — reference implementation (300 lines) |
| [`playground/index.html`](https://raw.githack.com/MaurerAnton/projectforge-dynamiclayout/master/playground/index.html) | Live playground with JsLayout DSL |
