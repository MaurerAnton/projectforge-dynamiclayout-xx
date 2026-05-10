// DynamicLayout Web Components — framework-agnostic custom elements.
// Works in any HTML page, with any framework (React, Vue, Angular, Svelte)
// or without any framework at all. Standard Custom Elements v1.
//
// Example (any HTML page):
//   <dl-layout id="mylayout"></dl-layout>
//   <script>
//     import './dynamiclayout-wc.js'
//     mylayout.render({ title: 'Hi', uid: '1', layout: [{ type: 'LABEL', key: 'l', label: 'Hello' }] })
//   </script>

const REGISTRY = {}

function register(type, fn) { REGISTRY[type] = fn }

class DLRenderer {
  constructor(root) {
    this.root = root
    this.data = {}
    this.errors = []
  }

  render(spec, data = {}, errors = []) {
    this.data = data || {}
    this.errors = errors || []
    this.root.innerHTML = ''
    if (!spec) return

    const layout = spec.layout || []
    const actions = spec.actions || []

    if (spec.title) {
      const h = document.createElement('h4')
      h.textContent = spec.title
      this.root.appendChild(h)
    }

    const layoutDiv = document.createElement('div')
    layoutDiv.className = 'dl-layout'
    layout.forEach(el => layoutDiv.appendChild(this._renderEl(el)))
    this.root.appendChild(layoutDiv)

    if (actions.length) {
      const actionDiv = document.createElement('div')
      actionDiv.style.cssText = 'display:flex;gap:8px;margin-top:16px;padding-top:16px;border-top:1px solid #dee2e6'
      actions.forEach(el => actionDiv.appendChild(this._renderEl(el)))
      this.root.appendChild(actionDiv)
    }
  }

  _renderEl(el) {
    const fn = REGISTRY[el.type]
    if (!fn) {
      const span = document.createElement('span')
      span.style.color = 'red'
      span.textContent = `Unknown: ${el.type}`
      return span
    }
    return fn.call(this, el)
  }

  _children(content) {
    const frag = document.createDocumentFragment()
    if (content) content.forEach(c => frag.appendChild(this._renderEl(c)))
    return frag
  }

  setData(update) {
    Object.assign(this.data, update)
    this.root.dispatchEvent(new CustomEvent('dl-update', { detail: { ...this.data }, bubbles: true }))
  }

  fireAction(id, responseAction) {
    this.root.dispatchEvent(new CustomEvent('dl-action', { detail: { id, responseAction }, bubbles: true }))
  }
}

// ── Container renderers ──

register('ROW', function(el) {
  const d = document.createElement('div'); d.className = 'dl-row'; d.appendChild(this._children(el.content)); return d
})
register('COL', function(el) {
  const d = document.createElement('div'); d.className = 'dl-col'; d.appendChild(this._children(el.content)); return d
})
register('GROUP', function(el) {
  const d = document.createElement('div'); d.className = 'dl-group'; d.appendChild(this._children(el.content)); return d
})
register('FIELDSET', function(el) {
  const fs = document.createElement('fieldset')
  if (el.title) { const lg = document.createElement('legend'); lg.textContent = el.title; fs.appendChild(lg) }
  fs.appendChild(this._children(el.content))
  return fs
})
register('INLINE_GROUP', function(el) {
  const d = document.createElement('div'); d.style.cssText = 'display:inline-flex;gap:0.5rem;align-items:center'; d.appendChild(this._children(el.content)); return d
})
register('FRAGMENT', function(el) {
  return this._children(el.content)
})

// ── Display renderers ──

register('LABEL', function(el) {
  const lb = document.createElement('label'); lb.style.cssText = 'display:block;margin-bottom:4px;font-weight:500'; lb.textContent = el.label || ''; return lb
})
register('ALERT', function(el) {
  const bg = { info:'#cff4fc', warning:'#fff3cd', danger:'#f8d7da', success:'#d1e7dd' }
  const tx = { info:'#055160', warning:'#664d03', danger:'#842029', success:'#0f5132' }
  const d = document.createElement('div')
  d.style.cssText = `padding:12px;background:${bg[el.color]||bg.info};color:${tx[el.color]||tx.info};border-radius:6px;margin-bottom:16px`
  d.textContent = el.message || ''; return d
})
register('BADGE', function(el) {
  const cols = { primary:'#0d6efd', secondary:'#6c757d', success:'#198754', danger:'#dc3545' }
  const s = document.createElement('span')
  s.style.cssText = `display:inline-block;padding:3px 8px;font-size:12px;font-weight:700;background:${cols[el.color]||'#6c757d'};color:#fff;border-radius:4px`
  s.textContent = el.title || ''; return s
})
register('SPACER', function(el) {
  const d = document.createElement('div'); d.style.height = (el.width || 20) + 'px'; return d
})
register('PROGRESS', function(el) {
  const cols = { primary:'#0d6efd', success:'#198754', danger:'#dc3545' }
  const wr = document.createElement('div')
  if (el.label) { const lb = document.createElement('div'); lb.style.marginBottom = '4px'; lb.textContent = el.label; wr.appendChild(lb) }
  const bar = document.createElement('div'); bar.style.cssText = 'height:20px;background:#e9ecef;border-radius:4px;overflow:hidden'
  const fill = document.createElement('div'); fill.style.cssText = `width:${el.progress||0}%;height:100%;background:${cols[el.color]||cols.primary};transition:width 0.3s`
  bar.appendChild(fill); wr.appendChild(bar); return wr
})

// ── Input renderers ──

register('INPUT', function(el) {
  const self = this
  const wr = document.createElement('div'); wr.className = 'dl-field'
  if (el.label) { const lb = document.createElement('label'); lb.textContent = el.label + (el.required ? ' *' : ''); wr.appendChild(lb) }
  const inp = document.createElement('input')
  inp.type = el.dataType === 'PASSWORD' ? 'password' : el.dataType === 'INTEGER' || el.dataType === 'LONG' ? 'number' : el.dataType === 'DATE' ? 'date' : 'text'
  inp.value = this.data[el.id] || ''
  if (el.maxLength) inp.maxLength = el.maxLength
  inp.style.cssText = 'width:100%;padding:6px 12px;border:1px solid #ced4da;border-radius:4px;box-sizing:border-box'
  inp.addEventListener('input', () => self.setData({ [el.id]: inp.value }))
  wr.appendChild(inp)

  const err = this.errors.find(e => e.fieldId === el.id)
  if (err) { const e = document.createElement('div'); e.style.cssText = 'color:#dc3545;font-size:12px'; e.textContent = err.message; wr.appendChild(e) }
  return wr
})

register('CHECKBOX', function(el) {
  const self = this
  const wr = document.createElement('div'); wr.style.cssText = 'margin-bottom:12px;display:flex;align-items:center;gap:8px'
  const cb = document.createElement('input'); cb.type = 'checkbox'; cb.checked = !!this.data[el.id]
  cb.addEventListener('change', () => self.setData({ [el.id]: cb.checked }))
  wr.appendChild(cb)
  if (el.label) { const lb = document.createElement('label'); lb.textContent = el.label; wr.appendChild(lb) }
  return wr
})

register('TEXTAREA', function(el) {
  const self = this
  const wr = document.createElement('div'); wr.className = 'dl-field'
  if (el.label) { const lb = document.createElement('label'); lb.textContent = el.label; wr.appendChild(lb) }
  const ta = document.createElement('textarea'); ta.rows = el.rows || 3; ta.value = this.data[el.id] || ''
  ta.style.cssText = 'width:100%;padding:6px 12px;border:1px solid #ced4da;border-radius:4px;box-sizing:border-box'
  ta.addEventListener('input', () => self.setData({ [el.id]: ta.value }))
  wr.appendChild(ta); return wr
})

register('SELECT', function(el) {
  const self = this
  const wr = document.createElement('div'); wr.className = 'dl-field'
  if (el.label) { const lb = document.createElement('label'); lb.textContent = el.label; wr.appendChild(lb) }
  const sel = document.createElement('select'); sel.style.cssText = 'width:100%;padding:6px 12px;border:1px solid #ced4da;border-radius:4px;box-sizing:border-box'
  const empty = document.createElement('option'); empty.value = ''; sel.appendChild(empty)
  ;(el.values || []).forEach(v => { const o = document.createElement('option'); o.value = v.id; o.textContent = v.displayName; if (this.data[el.id] == v.id) o.selected = true; sel.appendChild(o) })
  sel.addEventListener('change', () => self.setData({ [el.id]: sel.value }))
  wr.appendChild(sel); return wr
})

register('RATING', function(el) {
  const self = this
  const wr = document.createElement('div'); wr.className = 'dl-field'
  if (el.label) { const lb = document.createElement('label'); lb.textContent = el.label; wr.appendChild(lb) }
  const stars = document.createElement('div')
  for (let n = 1; n <= 5; n++) {
    const s = document.createElement('span'); s.style.cssText = 'cursor:pointer;font-size:24px'; s.textContent = '★'
    s.style.color = n <= (this.data[el.id] || 0) ? '#ffc107' : '#dee2e6'
    s.addEventListener('click', () => self.setData({ [el.id]: n }))
    stars.appendChild(s)
  }
  wr.appendChild(stars); return wr
})

register('READONLY_FIELD', function(el) {
  const wr = document.createElement('div'); wr.className = 'dl-field'
  if (el.label) { const lb = document.createElement('label'); lb.textContent = el.label; wr.appendChild(lb) }
  const dv = document.createElement('div'); dv.style.cssText = 'padding:6px 12px;background:#f8f9fa;border-radius:4px'; dv.textContent = this.data[el.id] || '—'
  wr.appendChild(dv); return wr
})

// ── Action renderers ──

register('BUTTON', function(el) {
  const self = this
  const cols = { primary:'#0d6efd', secondary:'#6c757d', success:'#198754', danger:'#dc3545', warning:'#ffc107', info:'#0dcaf0' }
  const btn = document.createElement('button')
  btn.style.cssText = `padding:8px 16px;border:none;border-radius:4px;cursor:pointer;font-weight:600;background:${cols[el.color]||cols.primary};color:#fff;margin-right:8px`
  btn.textContent = el.title || el.id
  btn.addEventListener('click', () => self.fireAction(el.id, el.responseAction))
  return btn
})

// ── Custom Element ──

class DynamicLayoutElement extends HTMLElement {
  constructor() {
    super()
    this._renderer = new DLRenderer(this)
  }

  connectedCallback() { this.style.display = 'block'; this.style.fontFamily = 'system-ui, sans-serif' }

  render(spec, data = {}, errors = []) {
    this._renderer.render(spec, data, errors)
  }

  get data() { return this._renderer.data }
  set data(v) { this._renderer.data = v }
}

customElements.define('dl-layout', DynamicLayoutElement)
