# Getting Started: DynamicLayout from Scratch

This guide walks you from zero to a working DynamicLayout application.
You will learn how to:

1. Define UI on the server (Kotlin)
2. Receive JSON on the client (React)
3. Render the page

---

## Part 1. Backend: Kotlin + Spring Boot

### Step 1. Add dependency

```kotlin
// build.gradle.kts
repositories {
    mavenCentral()
}

dependencies {
    implementation("org.dynamiclayout:dynamiclayout-spring:0.1.0")
}
```

### Step 2. Create a REST controller

```kotlin
@RestController
@RequestMapping("/api/hello")
class HelloPageRest : AbstractDynamicPageRest() {
    @GetMapping
    fun getPage(): FormLayoutData {
        val layout = UILayout("'DynamicLayout Demo")

        layout.add(
            UIFieldset(title = "'User Info")
                .add(UIInput("name", label = "'Your Name"))
                .add(UIInput("email", label = "'Email"))
        )

        layout.addAction(UIButton.createDefaultButton(title = "'Submit"))
        processLayout(layout)
        return createFormLayoutData(layout = layout)
    }
}
```

### Step 3. Run

```bash
./gradlew bootRun
# GET http://localhost:8080/api/hello
```

Response:
```json
{
  "ui": {
    "title": "DynamicLayout Demo",
    "layout": [
      { "type": "FIELDSET", "key": "el-1", "title": "User Info",
        "content": [
          { "type": "INPUT", "key": "el-2", "id": "name", "label": "Your Name", "dataType": "STRING" },
          { "type": "INPUT", "key": "el-3", "id": "email", "label": "Email", "dataType": "STRING" }
        ]
      }
    ],
    "actions": [
      { "type": "BUTTON", "key": "el-4", "id": "save", "title": "Submit", "color": "primary", "default": true }
    ],
    "translations": { "cancel": "Cancel", "save": "Save", "yes": "Yes", "select.placeholder": "Select...", "finish": "Finish", "calendar.today": "Today" },
    "userAccess": { "cancel": true },
    "uid": "layout1712345678901"
  }
}
```

---

## Part 2. Frontend: React

### Step 1. Install package

```bash
npm install @dynamiclayout/react
```

### Step 2. Create the page component

```jsx
import { DynamicLayout, renderLayout, registerComponent } from '@dynamiclayout/react';

function App() {
    const [ui, setUi] = useState(null);
    const [data, setData] = useState({});

    useEffect(() => {
        fetch('/api/hello')
            .then(r => r.json())
            .then(d => setUi(d.ui));
    }, []);

    if (!ui) return <div>Loading...</div>;

    return (
        <DynamicLayout
            ui={ui}
            data={data}
            setData={(update) => setData(prev => ({ ...prev, ...update }))}
        />
    );
}
```

### Step 3. Handle button actions

```jsx
const handleAction = (action) => {
    if (action.id === 'save') {
        fetch('/api/hello/save', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    }
};

<DynamicLayout
    ui={ui}
    data={data}
    setData={setData}
    callAction={handleAction}
/>
```

---

## Part 3. Kotlin DSL Reference

### Containers

| Component | Kotlin | JSON type | Description |
|-----------|--------|-----------|----------|
| Row | `UIRow()` | `ROW` | Flexbox row |
| Column | `UICol(UILength(md=6))` | `COL` | Bootstrap column |
| Fieldset | `UIFieldset(title = "'Info")` | `FIELDSET` | Group with legend |
| Inline | `UIInlineGroup()` | `INLINE_GROUP` | Elements side by side |

### Input fields

| Component | Kotlin | JSON type | dataType |
|-----------|--------|-----------|----------|
| Text | `UIInput("name")` | `INPUT` | `STRING` |
| Number | `UIInput("age", dataType=UIDataType.INT)` | `INPUT` | `INT` |
| Date | `UIInput("date", dataType=UIDataType.DATE)` | `INPUT` | `DATE` |
| Password | `UIInput("pass", dataType=UIDataType.PASSWORD)` | `INPUT` | `PASSWORD` |
| Checkbox | `UICheckbox("agree")` | `CHECKBOX` | — |
| Textarea | `UITextArea("notes")` | `TEXTAREA` | — |
| Select | `UISelect("country", values=countries)` | `SELECT` | — |

### Display

| Component | Kotlin | Description |
|-----------|--------|----------|
| Text | `UILabel("'Hello")` | `'` prefix = literal (skip i18n) |
| Alert | `UIAlert(message="'Error", color="danger")` | Colors: `primary`, `success`, `danger`, `info`, `warning` |
| Badge | `UIBadge(title="'New", color="success")` | With pill shape |
| Progress | `UIProgress(id="job", value=50)` | Progress bar |
| Spacer | `UISpacer(width=2)` | Empty space |

### Buttons

```kotlin
UIButton.createDefaultButton(title = "'Send")    // primary, default
UIButton.createCancelButton()                     // secondary
UIButton.createSaveButton()                       // primary
UIButton.createDangerButton(id = "delete", title = "'Delete")

// Custom
UIButton.create(id = "custom", title = "'Click me", color = "info")
```

---

## Part 4. JSON Format (for frontend developers)

```typescript
interface FormLayoutData {
    data?: any;
    ui: {
        title: string;
        layout: UIElement[];
        actions?: UIElement[];
        translations: Record<string, string>;
        userAccess: { cancel: boolean };
        uid: string;
    };
}
```

Every UIElement has:
```typescript
interface UIElement {
    type: string;       // "ROW" | "COL" | "FIELDSET" | "INPUT" | "LABEL" | ...
    key: string;        // Unique key (generated server-side)
    // + type-specific fields
}
```

### Element types

**Containers** (have `content: UIElement[]`):
- `ROW`, `COL`, `FIELDSET`, `GROUP`, `INLINE_GROUP`

**Inputs** (have `id: string`):
- `INPUT` — `{id, label, dataType, required?, maxLength?}`
- `TEXTAREA` — `{id, label, rows?}`
- `CHECKBOX` — `{id, label}`
- `SELECT` — `{id, label, values: [{id, displayName}]}`
- `RADIOBUTTON` — `{id, name, value, label}`
- `READONLY_FIELD` — `{id, label}`

**Display:**
- `LABEL` — `{label, tooltip?}`
- `ALERT` — `{message, title?, color?}`
- `BADGE` — `{title, color?}`
- `SPACER` — `{width?}`

**Buttons:**
- `BUTTON` — `{id, title, color?, default?, confirmMessage?}`

---

## Part 5. DynamicLayout React API

### `<DynamicLayout>`

```jsx
<DynamicLayout
    ui={ui}
    data={data}
    setData={fn}
    callAction={fn}
    variables={{}}
    setVariables={fn}
    validationErrors={[]}
/>
```

### `renderLayout(content)`

Renders a UIElement array recursively:

```jsx
import { renderLayout } from '@dynamiclayout/react';
function MyWidget({ content }) {
    return <div>{renderLayout(content)}</div>;
}
```

### `registerComponent(type, component)`

Register a custom React component for a given type:

```jsx
import { registerComponent } from '@dynamiclayout/react';
registerComponent('MY_CHART', ({ data }) => <canvas />);
```

### `DynamicLayoutContext`

```jsx
import { DynamicLayoutContext } from '@dynamiclayout/react';
function MyField({ id }) {
    const { data, setData } = React.useContext(DynamicLayoutContext);
    return <input value={data[id] || ''} onChange={e => setData({ [id]: e.target.value })} />;
}
```

---

## Part 6. Examples

### Example 1: Feedback form (3 fields + button)

**Kotlin:**
```kotlin
val layout = UILayout("'Feedback")
layout.add(UIFieldset(title = "'Your message")
    .add(UIInput("name", label = "'Name", required = true))
    .add(UIInput("email", label = "'Email", required = true))
    .add(UITextArea("message", label = "'Message", rows = 5))
)
layout.addAction(UIButton.createDefaultButton(title = "'Send"))
processLayout(layout)
return createFormLayoutData(layout = layout)
```

### Example 2: Two-column layout

**Kotlin:**
```kotlin
layout.add(
    UIRow().add(
        UICol(UILength(xs = 12, md = 6))
            .add(UIInput("firstName", label = "'First Name"))
            .add(UIInput("email", label = "'Email")),
        UICol(UILength(xs = 12, md = 6))
            .add(UIInput("lastName", label = "'Last Name"))
            .add(UIInput("phone", label = "'Phone"))
    )
)
```

### Example 3: Static info page

**Kotlin:**
```kotlin
val layout = UILayout("'About")
layout.add(
    UIFieldset(title = "'About Us")
        .add(UILabel("'We build enterprise software."))
        .add(UILabel("'Contact: hello@example.com"))
)
processLayout(layout)
return createFormLayoutData(layout = layout)
```

---

## FAQ

**Q: Page is empty, console shows an error.**
A: Check the JSON — `ui.layout` must be an array. Each element needs `type` and `key`.

**Q: Input field doesn't update on typing.**
A: Make sure `setData` is passed to `<DynamicLayout>`. It should merge: `setData(update => prev => ({ ...prev, ...update }))`.

**Q: Button doesn't work.**
A: `callAction` is not implemented by default. Pass your own: `<DynamicLayout callAction={handleAction} />`.

**Q: Need custom validation.**
A: Pass `validationErrors={[{ fieldId: 'email', message: 'Invalid email' }]}`.

**Q: Server sends layout, client shows "Unknown type: XXX".**
A: Register the type: `registerComponent('XXX', YourComponent)`.
