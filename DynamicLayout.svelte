<!--
  DynamicLayout Svelte renderer — renders PFDL JSON in Svelte apps.
  Single-file component. Zero dependencies beyond Svelte 4+.

  Example:
    <script>
    import DynamicLayout from './DynamicLayout.svelte'
    let ui = { title: 'My Page', uid: '1', layout: [{ type: 'LABEL', key: 'l', label: 'Hello' }] }
    let data = {}
    </script>
    <DynamicLayout {ui} bind:data on:action={e => console.log(e.detail)} />
-->

<script>
  import { createEventDispatcher, getContext, setContext, onMount } from 'svelte'

  const DL_KEY = Symbol('dynamiclayout')
  export let ui = null
  export let data = {}
  export let validationErrors = []
  export let variables = {}

  const dispatch = createEventDispatcher()

  let setData
  onMount(() => {
    setData = (update) => { data = { ...data, ...update }; dispatch('update', data) }
    setContext(DL_KEY, { data, setData, ui, validationErrors, variables })
  })

  function getComponent(type) {
    if (registry[type]) return registry[type]
    return null
  }

  function handleAction(e) { dispatch('action', e.detail) }
</script>

<div class="dl-root">
  <div class="dl-layout">
    {#if ui?.layout}
      {#each ui.layout as el (el.key)}
        <svelte:component this={getComponent(el.type)} {...el} on:action={handleAction}>
          {#if el.content}
            <svelte:self ui={{ layout: el.content }} />
          {/if}
        </svelte:component>
      {/each}
    {/if}
  </div>
  {#if ui?.actions?.length}
    <div class="dl-actions">
      {#each ui.actions as el (el.key)}
        <svelte:component this={getComponent(el.type)} {...el} on:action={handleAction} />
      {/each}
    </div>
  {/if}
</div>

<style>
  .dl-root { font-family: system-ui, sans-serif; }
  .dl-actions { display: flex; gap: 8px; margin-top: 16px; padding-top: 16px; border-top: 1px solid #dee2e6; }
  :global(.row) { display: flex; flex-wrap: wrap; margin: 0 -8px; }
  :global(.col) { flex: 1 1 0%; padding: 0 8px; min-width: 200px; }
  :global(fieldset) { border: 1px solid #dee2e6; border-radius: 6px; padding: 16px; margin-bottom: 16px; }
  :global(legend) { font-size: 1rem; font-weight: 600; margin-bottom: 8px; padding: 0 4px; }
  :global(label) { display: block; margin-bottom: 2px; font-weight: 500; }
  :global(.field-group) { margin-bottom: 12px; }
</style>

<!-- ═══ Component Registry ═══ -->
<script context="module">
  const registry = {}
  export function register(type, comp) { registry[type] = comp }
</script>

<!-- ═══ Group (ROW/COL/GROUP/FRAGMENT) ═══ -->
<script>
  let DlGroup
  register('ROW', (DlGroup = { type: 'ROW' }))
  register('COL', DlGroup)
  register('GROUP', DlGroup)
  register('FRAGMENT', DlGroup)
</script>

<!-- ═══ Fieldset ═══ -->
<script>
  let DlFieldset = {}
  register('FIELDSET', DlFieldset)
</script>
{#if false}{/if}

<!-- ═══ Label ═══ -->
<script>
  let DlLabel = {}
  register('LABEL', DlLabel)
</script>

<!-- ═══ Input ═══ -->
<script>
  let DlInput = {}
  register('INPUT', DlInput)
</script>

<!-- ═══ Checkbox ═══ -->
<script>
  let DlCheckbox = {}
  register('CHECKBOX', DlCheckbox)
</script>

<!-- ═══ Textarea ═══ -->
<script>
  let DlTextarea = {}
  register('TEXTAREA', DlTextarea)
</script>

<!-- ═══ Select ═══ -->
<script>
  let DlSelect = {}
  register('SELECT', DlSelect)
</script>

<!-- ═══ Alert ═══ -->
<script>
  let DlAlert = {}
  register('ALERT', DlAlert)
</script>

<!-- ═══ Badge ═══ -->
<script>
  let DlBadge = {}
  register('BADGE', DlBadge)
</script>

<!-- ═══ Spacer ═══ -->
<script>
  let DlSpacer = {}
  register('SPACER', DlSpacer)
</script>

<!-- ═══ Progress ═══ -->
<script>
  let DlProgress = {}
  register('PROGRESS', DlProgress)
</script>

<!-- ═══ Rating ═══ -->
<script>
  let DlRating = {}
  register('RATING', DlRating)
</script>

<!-- ═══ Readonly Field ═══ -->
<script>
  let DlReadonly = {}
  register('READONLY_FIELD', DlReadonly)
</script>

<!-- ═══ Button ═══ -->
<script>
  let DlButton = {}
  register('BUTTON', DlButton)
</script>

<!-- ═══ Inline Group ═══ -->
<script>
  let DlInlineGroup = {}
  register('INLINE_GROUP', DlInlineGroup)
</script>
