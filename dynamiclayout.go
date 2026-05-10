// Package dynamiclayout generates DynamicLayout JSON from Go code.
//
// Single-file library. Zero dependencies outside the standard library.
// Works on any Go version >= 1.18.
//
// Example:
//
//	b := dl.Begin("My Page")
//	b.Fieldset("Info")
//	b.Label("Hello from Go!")
//	b.EndFieldset()
//	b.Button("ok", "OK", "primary", true)
//	json := b.End()
//	fmt.Println(json)
package dynamiclayout

import (
	"encoding/json"
	"fmt"
	"strings"
)

// UI element types
const (
	TypeRow           = "ROW"
	TypeCol           = "COL"
	TypeFieldset      = "FIELDSET"
	TypeGroup         = "GROUP"
	TypeInlineGroup   = "INLINE_GROUP"
	TypeFragment      = "FRAGMENT"
	TypeNamedContainer = "NAMED_CONTAINER"
	TypeLabel         = "LABEL"
	TypeInput         = "INPUT"
	TypeTextarea      = "TEXTAREA"
	TypeCheckbox      = "CHECKBOX"
	TypeSelect        = "SELECT"
	TypeCreatableSel  = "CREATABLE_SELECT"
	TypeRadioButton   = "RADIOBUTTON"
	TypeRating        = "RATING"
	TypeReadonlyField = "READONLY_FIELD"
	TypeButton        = "BUTTON"
	TypeAlert         = "ALERT"
	TypeBadge         = "BADGE"
	TypeBadgeList     = "BADGE_LIST"
	TypeProgress      = "PROGRESS"
	TypeSpacer        = "SPACER"
	TypeEditor        = "EDITOR"
	TypeList          = "LIST"
	TypeTable         = "TABLE"
	TypeTableColumn   = "TABLE_COLUMN"
	TypeAgGrid        = "AG_GRID"
	TypeAgGridListPg  = "AG_GRID_LIST_PAGE"
	TypeAgGridColDef  = "AG_GRID_COLUMN_DEF"
	TypeAttachmentLst = "ATTACHMENT_LIST"
	TypeDropArea      = "DROP_AREA"
	TypeCustomized    = "CUSTOMIZED"
	TypeFilterElement = "FILTER_ELEMENT"
)

// Bootstrap colors
const (
	ColorPrimary   = "primary"
	ColorSecondary = "secondary"
	ColorSuccess   = "success"
	ColorDanger    = "danger"
	ColorWarning   = "warning"
	ColorInfo      = "info"
	ColorLight     = "light"
	ColorDark      = "dark"
	ColorLink      = "link"
)

// Data types
const (
	DataTypeString    = "STRING"
	DataTypeInteger   = "INTEGER"
	DataTypeLong      = "LONG"
	DataTypeBigDec    = "BIG_DECIMAL"
	DataTypeStringArr = "STRING_ARRAY"
	DataTypeDate      = "DATE"
	DataTypeTime      = "TIME"
	DataTypeTimestamp = "TIMESTAMP"
	DataTypeBoolean   = "BOOLEAN"
	DataTypePassword  = "PASSWORD"
)

// Filter types
const (
	FilterText      = "TEXT"
	FilterNumber    = "NUMBER"
	FilterDate      = "DATE"
	FilterSelect    = "SELECT"
	FilterBoolean   = "BOOLEAN"
	FilterTimestamp = "TIMESTAMP"
)

// SelectValue is a dropdown option.
type SelectValue struct {
	ID          interface{} `json:"id"`
	DisplayName string      `json:"displayName"`
	Order       int         `json:"order,omitempty"`
}

// Badge is a badge/chip.
type Badge struct {
	Title string `json:"title"`
	Color string `json:"color,omitempty"`
	Pill  bool   `json:"pill,omitempty"`
}

// Length represents Bootstrap grid column widths.
type Length struct {
	XS int `json:"xs,omitempty"`
	SM int `json:"sm,omitempty"`
	MD int `json:"md,omitempty"`
	LG int `json:"lg,omitempty"`
	XL int `json:"xl,omitempty"`
}

// ResponseAction defines server behavior after a button click.
type ResponseAction struct {
	Type             string `json:"type"`
	URL              string `json:"url,omitempty"`
	Method           string `json:"method,omitempty"`
	TargetType       string `json:"targetType,omitempty"`
	TargetURL        string `json:"targetUrl,omitempty"`
	Message          string `json:"message,omitempty"`
	Color            string `json:"color,omitempty"`
	NoResponseAction bool   `json:"noResponseAction,omitempty"`
	ConfirmMessage   string `json:"confirmMessage,omitempty"`
}

// element is the internal representation of a UI element.
type element map[string]interface{}

// Element is the exported type for UI elements (used in column definitions etc.).
type Element = element

// Builder builds a DynamicLayout JSON document.
type Builder struct {
	title    string
	uid      string
	layout   []element
	actions  []element
	stack    []*[]element // stack of open containers
	counter  int
}

// Begin starts a new layout with the given title.
func Begin(title string) *Builder {
	b := &Builder{title: title, uid: fmt.Sprintf("layout_%d", nowMs())}
	b.stack = []*[]element{&b.layout}
	return b
}

// UID sets a custom unique layout identifier.
func (b *Builder) UID(uid string) *Builder { b.uid = uid; return b }

// add adds an element to the current container.
func (b *Builder) add(el element) element {
	top := b.stack[len(b.stack)-1]
	*top = append(*top, el)
	return el
}

// key generates a unique element key.
func (b *Builder) key(prefix string) string {
	b.counter++
	return fmt.Sprintf("%s_%d", prefix, b.counter)
}

// push enters a container (fieldset/row/col).
func (b *Builder) push(el element) {
	b.add(el)
	content := make([]element, 0)
	el["content"] = &content
	b.stack = append(b.stack, &content)
}

// pop exits the current container.
func (b *Builder) pop() {
	b.stack = b.stack[:len(b.stack)-1]
}

// --- Containers ---

// Fieldset opens a FIELDSET container with a title.
func (b *Builder) Fieldset(title string) *Builder {
	b.push(element{
		"type":  TypeFieldset,
		"key":   b.key("fs"),
		"title": title,
	})
	return b
}

// FieldsetCollapsed opens a collapsible FIELDSET.
func (b *Builder) FieldsetCollapsed(title string, collapsed bool) *Builder {
	b.push(element{
		"type":      TypeFieldset,
		"key":       b.key("fs"),
		"title":     title,
		"collapsed": collapsed,
	})
	return b
}

// EndFieldset closes the current FIELDSET.
func (b *Builder) EndFieldset() *Builder { b.pop(); return b }

// Row opens a ROW container.
func (b *Builder) Row() *Builder {
	b.push(element{"type": TypeRow, "key": b.key("r")})
	return b
}

// EndRow closes the current ROW.
func (b *Builder) EndRow() *Builder { b.pop(); return b }

// Col opens a COL container.
func (b *Builder) Col(length ...int) *Builder {
	el := element{"type": TypeCol, "key": b.key("c")}
	if len(length) >= 1 && length[0] > 0 {
		el["length"] = LengthFrom(length...)
	}
	b.push(el)
	return b
}

// EndCol closes the current COL.
func (b *Builder) EndCol() *Builder { b.pop(); return b }

// Group opens a GROUP container.
func (b *Builder) Group() *Builder {
	b.push(element{"type": TypeGroup, "key": b.key("g")})
	return b
}

// EndGroup closes the current GROUP.
func (b *Builder) EndGroup() *Builder { b.pop(); return b }

// InlineGroup opens an INLINE_GROUP container.
func (b *Builder) InlineGroup() *Builder {
	b.push(element{"type": TypeInlineGroup, "key": b.key("ig")})
	return b
}

// EndInlineGroup closes the current INLINE_GROUP.
func (b *Builder) EndInlineGroup() *Builder { b.pop(); return b }

// NamedContainer opens a NAMED_CONTAINER with an id.
func (b *Builder) NamedContainer(id string) *Builder {
	b.push(element{"type": TypeNamedContainer, "key": b.key("nc"), "id": id})
	return b
}

// EndNamedContainer closes the current NAMED_CONTAINER.
func (b *Builder) EndNamedContainer() *Builder { b.pop(); return b }

// List opens a repeatable LIST.
func (b *Builder) List(listID, elementVar, positionLabel string) *Builder {
	b.push(element{
		"type":          TypeList,
		"key":           b.key("li"),
		"listId":        listID,
		"elementVar":    elementVar,
		"positionLabel": positionLabel,
	})
	return b
}

// EndList closes the current LIST.
func (b *Builder) EndList() *Builder { b.pop(); return b }

// --- Display elements ---

// Label adds a LABEL with text.
func (b *Builder) Label(text string) *Builder {
	b.add(element{"type": TypeLabel, "key": b.key("l"), "label": text})
	return b
}

// Alert adds an ALERT notification.
func (b *Builder) Alert(message, color string) *Builder {
	el := element{"type": TypeAlert, "key": b.key("a"), "message": message}
	if color != "" { el["color"] = color }
	b.add(el)
	return b
}

// Badge adds a BADGE.
func (b *Builder) Badge(title, color string) *Builder {
	el := element{"type": TypeBadge, "key": b.key("bd"), "title": title}
	if color != "" { el["color"] = color }
	b.add(el)
	return b
}

// BadgeList adds a BADGE_LIST.
func (b *Builder) BadgeList(badges []Badge) *Builder {
	b.add(element{"type": TypeBadgeList, "key": b.key("bl"), "badgeList": badges})
	return b
}

// Progress adds a PROGRESS bar.
func (b *Builder) Progress(label string, pct int, color string) *Builder {
	el := element{"type": TypeProgress, "key": b.key("pr"), "progress": pct}
	if label != "" { el["label"] = label }
	if color != "" { el["color"] = color }
	b.add(el)
	return b
}

// Spacer adds a SPACER with a given height in px.
func (b *Builder) Spacer(height int) *Builder {
	b.add(element{"type": TypeSpacer, "key": b.key("sp"), "width": height})
	return b
}

// --- Input elements ---

// Input adds an INPUT field.
func (b *Builder) Input(id, label string, opts ...InputOpt) *Builder {
	el := element{"type": TypeInput, "key": b.key("i"), "id": id, "label": label}
	for _, o := range opts {
		o(el)
	}
	b.add(el)
	return b
}

// InputOpt is an option for Input().
type InputOpt func(el element)

// Required marks the input as required.
func Required() InputOpt { return func(el element) { el["required"] = true } }

// MaxLen sets maxLength on the input.
func MaxLen(n int) InputOpt { return func(el element) { el["maxLength"] = n } }

// DataTypeInput sets the dataType.
func DataTypeInput(dt string) InputOpt { return func(el element) { el["dataType"] = dt } }

// Focus sets auto-focus on the input.
func Focus() InputOpt { return func(el element) { el["focus"] = true } }

// InputColor sets the color.
func InputColor(c string) InputOpt { return func(el element) { el["color"] = c } }

// Pattern sets an HTML pattern.
func Pattern(p string) InputOpt { return func(el element) { el["pattern"] = p } }

// AutoComplete sets browser autocomplete.
func AutoComplete(v string) InputOpt { return func(el element) { el["autoComplete"] = v } }

// Tooltip sets a tooltip on the input.
func Tooltip(t string) InputOpt { return func(el element) { el["tooltip"] = t } }

// AdditionalLabel sets an additional label.
func AdditionalLabel(l string) InputOpt { return func(el element) { el["additionalLabel"] = l } }

// Textarea adds a TEXTAREA.
func (b *Builder) Textarea(id, label string, rows int) *Builder {
	el := element{"type": TypeTextarea, "key": b.key("ta"), "id": id, "label": label}
	if rows > 0 { el["rows"] = rows }
	b.add(el)
	return b
}

// Checkbox adds a CHECKBOX.
func (b *Builder) Checkbox(id, label string) *Builder {
	b.add(element{"type": TypeCheckbox, "key": b.key("cb"), "id": id, "label": label})
	return b
}

// Select adds a SELECT dropdown.
func (b *Builder) Select(id, label string, values []SelectValue) *Builder {
	b.add(element{
		"type":   TypeSelect,
		"key":    b.key("s"),
		"id":     id,
		"label":  label,
		"values": values,
	})
	return b
}

// SelectStrings adds a SELECT with string id/name pairs.
func (b *Builder) SelectStrings(id, label string, pairs ...[2]string) *Builder {
	vals := make([]SelectValue, len(pairs))
	for i, p := range pairs {
		vals[i] = SelectValue{ID: p[0], DisplayName: p[1]}
	}
	return b.Select(id, label, vals)
}

// CreatableSelect adds a CREATABLE_SELECT.
func (b *Builder) CreatableSelect(id, label string, values []SelectValue) *Builder {
	b.add(element{
		"type":   TypeCreatableSel,
		"key":    b.key("cs"),
		"id":     id,
		"label":  label,
		"values": values,
	})
	return b
}

// RadioButton adds a RADIOBUTTON group.
func (b *Builder) RadioButton(id, label string, values []SelectValue) *Builder {
	b.add(element{
		"type":   TypeRadioButton,
		"key":    b.key("rb"),
		"id":     id,
		"label":  label,
		"values": values,
	})
	return b
}

// Rating adds a star RATING input.
func (b *Builder) Rating(id, label string) *Builder {
	b.add(element{"type": TypeRating, "key": b.key("rt"), "id": id, "label": label})
	return b
}

// ReadonlyField adds a READONLY_FIELD.
func (b *Builder) ReadonlyField(id, label string) *Builder {
	b.add(element{"type": TypeReadonlyField, "key": b.key("ro"), "id": id, "label": label})
	return b
}

// Editor adds an EDITOR (code editor).
func (b *Builder) Editor(id, label string, rows int) *Builder {
	el := element{"type": TypeEditor, "key": b.key("ed"), "id": id, "label": label}
	if rows > 0 { el["rows"] = rows }
	b.add(el)
	return b
}

// --- Tables ---

// Table adds a TABLE with column definitions.
func (b *Builder) Table(id string, columns []Element) *Builder {
	el := element{"type": TypeTable, "key": b.key("tb"), "columns": columns}
	if id != "" { el["id"] = id }
	b.add(el)
	return b
}

// TableColumn creates a column definition for Table().
func (b *Builder) TableColumn(id, title string) Element {
	return element{"type": TypeTableColumn, "key": b.key("tc"), "id": id, "title": title}
}

// AgGrid adds an AG_GRID table.
func (b *Builder) AgGrid(id string, columns []Element) *Builder {
	el := element{"type": TypeAgGrid, "key": b.key("ag"), "columnDefs": columns}
	if id != "" { el["id"] = id }
	b.add(el)
	return b
}

// AgGridListPage adds an AG_GRID_LIST_PAGE.
func (b *Builder) AgGridListPage(id string, columns []Element) *Builder {
	el := element{"type": TypeAgGridListPg, "key": b.key("alp"), "columnDefs": columns}
	if id != "" { el["id"] = id }
	b.add(el)
	return b
}

// AgGridColumn creates a column definition for AgGrid()/AgGridListPage().
func (b *Builder) AgGridColumn(id, header string) Element {
	return element{"type": TypeAgGridColDef, "key": b.key("agc"), "id": id, "headerName": header}
}

// --- File ---

// AttachmentList adds an ATTACHMENT_LIST.
func (b *Builder) AttachmentList(id, label string) *Builder {
	b.add(element{"type": TypeAttachmentLst, "key": b.key("al"), "id": id, "label": label})
	return b
}

// DropArea adds a file DROP_AREA.
func (b *Builder) DropArea(id, label, accept string, multiple bool) *Builder {
	el := element{"type": TypeDropArea, "key": b.key("da"), "id": id, "label": label}
	if accept != "" { el["accept"] = accept }
	if multiple { el["multiple"] = true }
	b.add(el)
	return b
}

// --- Actions ---

// Button adds a BUTTON to the actions bar.
func (b *Builder) Button(id, title, color string, isDefault bool) *Builder {
	el := element{"type": TypeButton, "key": b.key("btn"), "id": id, "title": title, "color": color}
	if isDefault { el["default"] = true }
	b.actions = append(b.actions, el)
	return b
}

// ButtonWithAction adds a BUTTON with a ResponseAction.
func (b *Builder) ButtonWithAction(id, title, color string, action ResponseAction) *Builder {
	el := element{"type": TypeButton, "key": b.key("btn"), "id": id, "title": title, "color": color, "responseAction": action}
	b.actions = append(b.actions, el)
	return b
}

// --- Output ---

// layoutResult is the final JSON structure.
type layoutResult struct {
	UI uiResult `json:"ui"`
}

type uiResult struct {
	Title       string            `json:"title"`
	UID         string            `json:"uid"`
	Layout      []element         `json:"layout"`
	Actions     []element         `json:"actions,omitempty"`
	Translations map[string]string `json:"translations"`
	UserAccess  map[string]bool   `json:"userAccess"`
}

// End finalizes the layout and returns JSON.
// The builder can be discarded after this call.
func (b *Builder) End() string {
	for len(b.stack) > 1 {
		b.pop()
	}

	res := layoutResult{
		UI: uiResult{
			Title:        b.title,
			UID:          b.uid,
			Layout:       *b.stack[0],
			Actions:      b.actions,
			Translations: map[string]string{},
			UserAccess:   map[string]bool{"cancel": true},
		},
	}

	var sb strings.Builder
	enc := json.NewEncoder(&sb)
	enc.SetIndent("", "  ")
	enc.Encode(res)
	return strings.TrimSpace(sb.String())
}

// --- Helpers ---

// LengthFrom creates a Length from alternating breakpoint/width pairs.
// Example: LengthFrom(12, 6) sets xs=12, md=6.
func LengthFrom(sizes ...int) *Length {
	l := &Length{}
	for i := 0; i+1 < len(sizes); i += 2 {
		switch i / 2 {
		case 0: l.XS = sizes[i]; if i+1 < len(sizes) { l.SM = sizes[i+1] }
		}
	}
	// Simpler API: LengthFrom(xs, sm, md, lg, xl)
	if len(sizes) >= 1 { l.XS = sizes[0] }
	if len(sizes) >= 2 { l.SM = sizes[1] }
	if len(sizes) >= 3 { l.MD = sizes[2] }
	if len(sizes) >= 4 { l.LG = sizes[3] }
	if len(sizes) >= 5 { l.XL = sizes[4] }
	return l
}

// Section is a shortcut: Fieldset + Label + EndFieldset.
func (b *Builder) Section(fieldsetTitle, text string) *Builder {
	return b.Fieldset(fieldsetTitle).Label(text).EndFieldset()
}

// FeedbackForm adds a pre-built feedback form (name, email, message, Send button).
func (b *Builder) FeedbackForm() *Builder {
	b.Fieldset("Your Details")
	b.Input("name", "Name", Required())
	b.Input("email", "Email", Required())
	b.Textarea("message", "Message", 5)
	b.EndFieldset()
	b.Button("send", "Send", ColorPrimary, true)
	b.Button("cancel", "Cancel", ColorSecondary, false)
	return b
}

// nowMs is a placeholder for time.Now().UnixMilli().
// Keeps zero external deps (no "time" import in simple builds).
var nowMs = func() int64 { return 0 }
