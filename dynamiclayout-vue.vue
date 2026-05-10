<!-- DynamicLayout Vue 3 renderer — renders PFDL JSON in Vue apps.
  Single-file component library. Zero dependencies beyond Vue 3.
  Use standalone with <script setup> or as a plugin.

  Example (standalone):
    <template>
      <DynamicLayout :ui="layoutJson.ui" :data="formData" @update="onUpdate" />
    </template>
    <script setup>
    import { ref } from 'vue'
    import DynamicLayout from './dynamiclayout-vue.js'
    const formData = ref({})
    </script>
  -->

<template>
  <div class="dl-root">
    <div class="dl-layout" v-if="ui">
      <template v-for="(el, i) in ui.layout" :key="el.key || i">
        <component :is="getComponent(el.type)" v-bind="el" @action="handleAction" />
      </template>
    </div>
    <div class="dl-actions" v-if="ui?.actions?.length">
      <template v-for="(el, i) in ui.actions" :key="el.key || i">
        <component :is="getComponent(el.type)" v-bind="el" @action="handleAction" />
      </template>
    </div>
  </div>
</template>

<script>
import { h, defineComponent, provide, inject } from 'vue'

// ── DynamicLayout Context ──
const DL_KEY = Symbol('dynamiclayout')

export function useDynamicLayout() { return inject(DL_KEY) }

// ── Component Registry ──
const registry = {}

function register(type, comp) { registry[type] = comp }

function renderChildren(content, ctx) {
  if (!content) return []
  return content.map((el) => {
    const Comp = registry[el.type]
    if (!Comp) return h('span', { style: { color: 'red' } }, `Unknown: ${el.type}`)
    return h(Comp, { key: el.key, ...el, dl: ctx })
  })
}

// ── Container components ──

const DlGroup = defineComponent({
  props: ['type', 'key', 'content', 'dl'],
  setup(props) {
    const Tag = props.type === 'ROW' ? 'div' : props.type === 'COL' ? 'div' : props.type === 'GROUP' ? 'div' : 'template'
    const cls = props.type === 'ROW' ? 'row' : props.type === 'COL' ? 'col' : ''
    return () => h(Tag, { class: cls }, renderChildren(props.content, props.dl))
  }
})

const DlFieldset = defineComponent({
  props: ['key', 'title', 'content', 'collapsed', 'dl'],
  setup(props) {
    const { ref } = require('vue')
    const open = ref(props.collapsed !== true)
    function toggle() { if (props.collapsed != null) open.value = !open.value }
    return () => h('fieldset', {}, [
      props.title ? h('legend', { style: { cursor: props.collapsed != null ? 'pointer' : 'default' }, onClick: toggle }, props.title) : null,
      open.value ? renderChildren(props.content, props.dl) : null
    ])
  }
})

const DlInlineGroup = defineComponent({
  props: ['key', 'content', 'dl'],
  setup(props) {
    return () => h('div', { style: { display: 'inline-flex', gap: '0.5rem', alignItems: 'center' } }, renderChildren(props.content, props.dl))
  }
})

// ── Display components ──

const DlLabel = defineComponent({
  props: ['key', 'label'],
  setup(props) {
    return () => h('label', { style: { display: 'block', marginBottom: '4px', fontWeight: 500 } }, props.label)
  }
})

const DlAlert = defineComponent({
  props: ['key', 'message', 'color'],
  setup(props) {
    const bg = { info: '#cff4fc', warning: '#fff3cd', danger: '#f8d7da', success: '#d1e7dd' }
    const txt = { info: '#055160', warning: '#664d03', danger: '#842029', success: '#0f5132' }
    return () => h('div', { style: { padding: '12px', backgroundColor: bg[props.color] || bg.info, color: txt[props.color] || txt.info, borderRadius: '6px', marginBottom: '16px' } }, props.message)
  }
})

const DlBadge = defineComponent({
  props: ['key', 'title', 'color'],
  setup(props) {
    const colors = { primary: '#0d6efd', secondary: '#6c757d', success: '#198754', danger: '#dc3545', warning: '#ffc107', info: '#0dcaf0' }
    return () => h('span', { style: { display: 'inline-block', padding: '3px 8px', fontSize: '12px', fontWeight: 700, backgroundColor: colors[props.color] || '#6c757d', color: '#fff', borderRadius: '4px' } }, props.title)
  }
})

const DlSpacer = defineComponent({
  props: ['key', 'width'],
  setup(props) { return () => h('div', { style: { height: (props.width || 20) + 'px' } }) }
})

const DlProgress = defineComponent({
  props: ['key', 'label', 'progress', 'color'],
  setup(props) {
    const colors = { primary: '#0d6efd', success: '#198754', danger: '#dc3545', warning: '#ffc107', info: '#0dcaf0' }
    return () => h('div', {}, [
      props.label ? h('div', { style: { marginBottom: '4px' } }, props.label) : null,
      h('div', { style: { height: '20px', backgroundColor: '#e9ecef', borderRadius: '4px', overflow: 'hidden' } }, [
        h('div', { style: { width: (props.progress || 0) + '%', height: '100%', backgroundColor: colors[props.color] || colors.primary, transition: 'width 0.3s' } })
      ])
    ])
  }
})

// ── Input components ──

const DlInput = defineComponent({
  props: ['key', 'id', 'label', 'required', 'dataType', 'maxLength', 'dl'],
  setup(props) {
    const ctx = props.dl || useDynamicLayout()
    return () => {
      const val = ctx?.data[props.id] || ''
      const err = ctx?.validationErrors?.find(e => e.fieldId === props.id)
      return h('div', { style: { marginBottom: '12px' } }, [
        props.label ? h('label', { style: { display: 'block', marginBottom: '2px' } }, props.label + (props.required ? ' *' : '')) : null,
        h('input', {
          value: val,
          type: props.dataType === 'PASSWORD' ? 'password' : props.dataType === 'INTEGER' || props.dataType === 'LONG' ? 'number' : props.dataType === 'DATE' ? 'date' : 'text',
          maxlength: props.maxLength || null,
          style: { width: '100%', padding: '6px 12px', border: '1px solid ' + (err ? '#dc3545' : '#ced4da'), borderRadius: '4px' },
          onInput: e => ctx?.setData({ [props.id]: e.target.value })
        }),
        err ? h('div', { style: { color: '#dc3545', fontSize: '12px' } }, err.message) : null
      ])
    }
  }
})

const DlCheckbox = defineComponent({
  props: ['key', 'id', 'label', 'dl'],
  setup(props) {
    const ctx = props.dl || useDynamicLayout()
    return () => h('div', { style: { marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' } }, [
      h('input', {
        type: 'checkbox',
        checked: !!ctx?.data[props.id],
        onChange: e => ctx?.setData({ [props.id]: e.target.checked })
      }),
      props.label ? h('label', {}, props.label) : null
    ])
  }
})

const DlTextarea = defineComponent({
  props: ['key', 'id', 'label', 'rows', 'dl'],
  setup(props) {
    const ctx = props.dl || useDynamicLayout()
    return () => h('div', { style: { marginBottom: '12px' } }, [
      props.label ? h('label', { style: { display: 'block', marginBottom: '2px' } }, props.label) : null,
      h('textarea', {
        value: ctx?.data[props.id] || '',
        rows: props.rows || 3,
        style: { width: '100%', padding: '6px 12px', border: '1px solid #ced4da', borderRadius: '4px' },
        onInput: e => ctx?.setData({ [props.id]: e.target.value })
      })
    ])
  }
})

const DlSelect = defineComponent({
  props: ['key', 'id', 'label', 'values', 'dl'],
  setup(props) {
    const ctx = props.dl || useDynamicLayout()
    return () => h('div', { style: { marginBottom: '12px' } }, [
      props.label ? h('label', { style: { display: 'block', marginBottom: '2px' } }, props.label) : null,
      h('select', {
        value: ctx?.data[props.id] || '',
        style: { width: '100%', padding: '6px 12px', border: '1px solid #ced4da', borderRadius: '4px' },
        onChange: e => ctx?.setData({ [props.id]: e.target.value })
      }, [
        h('option', { value: '' }, ''),
        ...(props.values || []).map(v => h('option', { key: v.id, value: v.id }, v.displayName))
      ])
    ])
  }
})

const DlRating = defineComponent({
  props: ['key', 'id', 'label', 'dl'],
  setup(props) {
    const ctx = props.dl || useDynamicLayout()
    const stars = ref(ctx?.data[props.id] || 0)
    return () => h('div', { style: { marginBottom: '12px' } }, [
      props.label ? h('label', { style: { display: 'block', marginBottom: '2px' } }, props.label) : null,
      h('div', {}, [1,2,3,4,5].map(n => h('span', {
        key: n, style: { cursor: 'pointer', fontSize: '24px', color: n <= stars.value ? '#ffc107' : '#dee2e6' },
        onClick: () => { stars.value = n; ctx?.setData({ [props.id]: n }) }
      }, '★')))
    ])
  }
})

const DlReadonly = defineComponent({
  props: ['key', 'id', 'label', 'dl'],
  setup(props) {
    const ctx = props.dl || useDynamicLayout()
    return () => h('div', { style: { marginBottom: '12px' } }, [
      props.label ? h('label', { style: { display: 'block', marginBottom: '2px', fontWeight: 500 } }, props.label) : null,
      h('div', { style: { padding: '6px 12px', backgroundColor: '#f8f9fa', borderRadius: '4px' } }, ctx?.data[props.id] || '—')
    ])
  }
})

// ── Action component ──

const DlButton = defineComponent({
  props: ['key', 'id', 'title', 'color', 'default', 'responseAction', 'dl'],
  emits: ['action'],
  setup(props, { emit }) {
    const colors = { primary: '#0d6efd', secondary: '#6c757d', success: '#198754', danger: '#dc3545', warning: '#ffc107', info: '#0dcaf0' }
    return () => h('button', {
      style: { padding: '8px 16px', border: 'none', borderRadius: '4px', cursor: 'pointer', fontWeight: 600, backgroundColor: colors[props.color] || colors.primary, color: '#fff', marginRight: '8px' },
      onClick: () => emit('action', props.responseAction || { type: props.id })
    }, props.title || props.id)
  }
})

// ── Register all components ──
register('ROW', DlGroup)
register('COL', DlGroup)
register('GROUP', DlGroup)
register('FRAGMENT', DlGroup)
register('FIELDSET', DlFieldset)
register('INLINE_GROUP', DlInlineGroup)
register('LABEL', DlLabel)
register('ALERT', DlAlert)
register('BADGE', DlBadge)
register('SPACER', DlSpacer)
register('PROGRESS', DlProgress)
register('INPUT', DlInput)
register('CHECKBOX', DlCheckbox)
register('TEXTAREA', DlTextarea)
register('SELECT', DlSelect)
register('RATING', DlRating)
register('READONLY_FIELD', DlReadonly)
register('BUTTON', DlButton)

// ── DynamicLayout Root Component ──
export default defineComponent({
  name: 'DynamicLayout',
  props: {
    ui: { type: Object, required: true },
    data: { type: Object, default: () => ({}) },
    validationErrors: { type: Array, default: () => [] },
    variables: { type: Object, default: () => ({}) }
  },
  emits: ['update', 'action'],
  setup(props, { emit }) {
    const data = reactive({ ...props.data })
    function setData(update) {
      Object.assign(data, update)
      emit('update', { ...data })
    }
    const ctx = reactive({
      data, setData, ui: props.ui,
      validationErrors: props.validationErrors, variables: props.variables,
      renderLayout: (content) => renderChildren(content, ctx)
    })
    provide(DL_KEY, ctx)

    function getComponent(type) {
      return registry[type] || 'span'
    }
    function handleAction(action) {
      emit('action', action)
    }

    return { getComponent, handleAction, ui: props.ui }
  }
})
</script>

<style scoped>
.dl-root { font-family: system-ui, sans-serif; }
.dl-layout { }
.dl-actions { display: flex; gap: 8px; margin-top: 16px; padding-top: 16px; border-top: 1px solid #dee2e6; }
.row { display: flex; flex-wrap: wrap; margin: 0 -8px; }
.col { flex: 1 1 0%; padding: 0 8px; min-width: 200px; }
fieldset { border: 1px solid #dee2e6; border-radius: 6px; padding: 16px; margin-bottom: 16px; }
legend { font-size: 1rem; font-weight: 600; margin-bottom: 8px; padding: 0 4px; }
</style>
