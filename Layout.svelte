<!--
  DynamicLayout Svelte 5 renderer — renders PFDL JSON in Svelte 5 apps.
  Single-file. Zero dependencies. Uses Svelte 5 runes ($state, $effect).

  Example:
    <script>
    import Layout from './Layout.svelte'
    let spec = { title: 'My Page', uid: '1', layout: [{ type: 'LABEL', key: 'l', label: 'Hi' }] }
    let form = {}
    </script>
    <Layout spec={spec.ui} bind:data={form} onaction={e => console.log(e.detail)} />
-->
<script module>
  // ── Component renderers (pure functions returning DOM) ──
  export const renderers = {}

  function renderLayout(content, ctx) {
    if (!content) return ''
    return content.map(el => {
      const fn = renderers[el.type]
      if (!fn) return `<span style="color:red">Unknown: ${el.type}</span>`
      return fn(el, ctx)
    }).join('')
  }

  renderers['ROW'] = (el, ctx) => `<div class="dl-row">${renderLayout(el.content, ctx)}</div>`
  renderers['COL'] = (el, ctx) => `<div class="dl-col">${renderLayout(el.content, ctx)}</div>`
  renderers['GROUP'] = (el, ctx) => `<div class="dl-group">${renderLayout(el.content, ctx)}</div>`
  renderers['FIELDSET'] = (el, ctx) => `<fieldset><legend>${el.title || ''}</legend>${renderLayout(el.content, ctx)}</fieldset>`
  renderers['INLINE_GROUP'] = (el, ctx) => `<div style="display:inline-flex;gap:0.5rem;align-items:center">${renderLayout(el.content, ctx)}</div>`
  renderers['FRAGMENT'] = (el, ctx) => renderLayout(el.content, ctx)

  renderers['LABEL'] = (el) => `<label style="display:block;margin-bottom:4px;font-weight:500">${el.label || ''}</label>`
  renderers['ALERT'] = (el) => {
    const bg = { info:'#cff4fc', warning:'#fff3cd', danger:'#f8d7da', success:'#d1e7dd' }
    const tx = { info:'#055160', warning:'#664d03', danger:'#842029', success:'#0f5132' }
    return `<div style="padding:12px;background:${bg[el.color]||bg.info};color:${tx[el.color]||tx.info};border-radius:6px;margin-bottom:16px">${el.message||''}</div>`
  }
  renderers['BADGE'] = (el) => {
    const cols = { primary:'#0d6efd', secondary:'#6c757d', success:'#198754', danger:'#dc3545' }
    return `<span style="display:inline-block;padding:3px 8px;font-size:12px;font-weight:700;background:${cols[el.color]||'#6c757d'};color:#fff;border-radius:4px">${el.title||''}</span>`
  }
  renderers['SPACER'] = (el) => `<div style="height:${el.width||20}px"></div>`
  renderers['PROGRESS'] = (el) => {
    const cols = { primary:'#0d6efd', success:'#198754', danger:'#dc3545' }
    return `<div>${el.label?`<div style="margin-bottom:4px">${el.label}</div>`:''}<div style="height:20px;background:#e9ecef;border-radius:4px;overflow:hidden"><div style="width:${el.progress||0}%;height:100%;background:${cols[el.color]||cols.primary};transition:width 0.3s"></div></div></div>`
  }

  renderers['INPUT'] = (el, ctx) => {
    const v = ctx.data[el.id] || ''
    const tp = el.dataType === 'PASSWORD' ? 'password' : el.dataType === 'INTEGER' || el.dataType === 'LONG' ? 'number' : el.dataType === 'DATE' ? 'date' : 'text'
    return `<div class="field"><label>${el.label||''}${el.required?' *':''}</label><input type="${tp}" value="${v}" maxlength="${el.maxLength||''}" data-id="${el.id}" class="dl-input" /></div>`
  }
  renderers['CHECKBOX'] = (el, ctx) => {
    const ck = ctx.data[el.id] ? 'checked' : ''
    return `<div style="margin-bottom:12px;display:flex;align-items:center;gap:8px"><input type="checkbox" ${ck} data-id="${el.id}" class="dl-checkbox" />${el.label?`<label>${el.label}</label>`:''}</div>`
  }
  renderers['TEXTAREA'] = (el, ctx) => {
    return `<div class="field"><label>${el.label||''}</label><textarea rows="${el.rows||3}" data-id="${el.id}" class="dl-textarea">${ctx.data[el.id]||''}</textarea></div>`
  }
  renderers['SELECT'] = (el, ctx) => {
    const opts = (el.values||[]).map(v => `<option value="${v.id}" ${ctx.data[el.id]==v.id?'selected':''}>${v.displayName}</option>`).join('')
    return `<div class="field"><label>${el.label||''}</label><select data-id="${el.id}" class="dl-select"><option value=""></option>${opts}</select></div>`
  }
  renderers['RATING'] = (el, ctx) => {
    const r = ctx.data[el.id] || 0
    const stars = [1,2,3,4,5].map(n => `<span style="cursor:pointer;font-size:24px;color:${n<=r?'#ffc107':'#dee2e6'}" data-rating="${n}" data-id="${el.id}" class="dl-rating">★</span>`).join('')
    return `<div class="field"><label>${el.label||''}</label><div>${stars}</div></div>`
  }
  renderers['READONLY_FIELD'] = (el, ctx) => {
    return `<div class="field"><label>${el.label||''}</label><div style="padding:6px 12px;background:#f8f9fa;border-radius:4px">${ctx.data[el.id]||'—'}</div></div>`
  }
  renderers['BUTTON'] = (el, ctx) => {
    const cols = { primary:'#0d6efd', secondary:'#6c757d', success:'#198754', danger:'#dc3545', warning:'#ffc107', info:'#0dcaf0' }
    return `<button style="padding:8px 16px;border:none;border-radius:4px;cursor:pointer;font-weight:600;background:${cols[el.color]||cols.primary};color:#fff;margin-right:8px" data-action-id="${el.id}" class="dl-button">${el.title||el.id}</button>`
  }
</script>

<script>
  let { spec = null, data = $bindable({}), validationErrors = [], onaction } = $props()

  let html = $state('')
  let uid = $state('')
  let title = $state('')
  let actions = $state([])

  $effect(() => {
    if (!spec) return
    title = spec.title
    uid = spec.uid
    actions = spec.actions || []
    const ctx = { data, setData: (u) => data = {...data, ...u}, validationErrors }
    html = renderLayout(spec.layout, ctx)
  })

  function delegate(e) {
    const el = e.target
    if (el.classList.contains('dl-input') || el.classList.contains('dl-textarea') || el.classList.contains('dl-select')) {
      data = { ...data, [el.dataset.id]: el.value }
    } else if (el.classList.contains('dl-checkbox')) {
      data = { ...data, [el.dataset.id]: el.checked }
    } else if (el.classList.contains('dl-rating')) {
      data = { ...data, [el.dataset.id]: parseInt(el.dataset.rating) }
    } else if (el.classList.contains('dl-button')) {
      onaction?.({ id: el.dataset.actionId })
    }
  }

  function actHtml() {
    if (!actions.length) return ''
    const cols = { primary:'#0d6efd', secondary:'#6c757d', success:'#198754', danger:'#dc3545' }
    return `<div style="display:flex;gap:8px;margin-top:16px;padding-top:16px;border-top:1px solid #dee2e6">${actions.map(a => `<button style="padding:8px 16px;border:none;border-radius:4px;cursor:pointer;font-weight:600;background:${cols[a.color]||cols.primary};color:#fff" data-action-id="${a.id}" class="dl-button">${a.title||a.id}</button>`).join('')}</div>`
  }
</script>

<div class="dl-root" oninput={delegate} onchange={delegate} onclick={delegate}>
  {#if title}<h4>{title}</h4>{/if}
  <div class="dl-layout">{@html html}</div>
  <div class="dl-actions">{@html actHtml()}</div>
</div>

<style>
  .dl-root { font-family: system-ui, sans-serif; }
  :global(.dl-row) { display: flex; flex-wrap: wrap; margin: 0 -8px; }
  :global(.dl-col) { flex: 1 1 0%; padding: 0 8px; min-width: 200px; }
  :global(.dl-group) { margin-bottom: 8px; }
  :global(fieldset) { border: 1px solid #dee2e6; border-radius: 6px; padding: 16px; margin-bottom: 16px; }
  :global(legend) { font-size: 1rem; font-weight: 600; margin-bottom: 8px; padding: 0 4px; }
  :global(.field) { margin-bottom: 12px; }
  :global(.field label) { display: block; margin-bottom: 2px; font-weight: 500; }
  :global(.field input):not([type=checkbox]),
  :global(.field textarea),
  :global(.field select) { width: 100%; padding: 6px 12px; border: 1px solid #ced4da; border-radius: 4px; box-sizing: border-box; }
</style>
