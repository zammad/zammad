<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, nextTick, toRef, useTemplateRef, watch, type Ref } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormRef, FormSchemaField, FormFieldValue } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'

import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'
import type { FilterSelectorEntityOverride } from '#desktop/components/Search/types.ts'

interface FilterUpdaterFields {
  filterRelationFields: Array<{ name: string; relation: string }>
  filterAutocompleteFields: Array<{ name: string; autocompleteFilterType: string }>
}

interface Props {
  entity: string
  filters?: FilterSelectorEntry[]
  filterAttributes?: FilterAttribute[]
  filterAttributesOverride?: FilterSelectorEntityOverride[]
  filterUpdaterFields?: FilterUpdaterFields
}

const props = withDefaults(defineProps<Props>(), {
  filters: () => [],
  filterAttributes: () => [],
  filterUpdaterFields: () => ({ filterRelationFields: [], filterAutocompleteFields: [] }),
})

const emit = defineEmits<{
  'filters-changed': [entity: string, value: FilterSelectorEntry[]]
}>()

const formInstance = useTemplateRef('form')

const { updateFieldValues, formReset, triggerFormUpdater } = useForm(formInstance as Ref<FormRef>)

// Pass as refs, not by value: `Form` resolves the schema once, so a plain
// `props.x` would be captured statically and later updates (e.g. the
// config-driven `filterAttributesOverride`) would never reach the live field.
// Vue unwraps refs inside the reactive schema data, keeping them reactive.
const filterAttributes = toRef(props, 'filterAttributes')
const filterAttributesOverride = toRef(props, 'filterAttributesOverride')

const schema = computed<FormSchemaField[]>(() => [
  {
    type: 'filterSelector',
    name: 'filters',
    props: {
      filterAttributes,
      filterAttributesOverride,
    },
  },
])

// Wire up the form updater whenever the entity has *any* server-resolvable
// filter fields — relation-typed (group/state/priority option lists, which
// the backend resolves only on the initial call) or autocomplete-typed
// (customer/organization/owner option prefill for an already-set value,
// re-resolved on every form change so cross-tab sync / taskbar restore
// land their option labels). Entities with neither (e.g. Organization,
// today) stay off the updater path entirely so it doesn't emit empty
// roundtrips on every keystroke.
const needsFormUpdater = computed(
  () =>
    props.filterUpdaterFields.filterRelationFields.length > 0 ||
    props.filterUpdaterFields.filterAutocompleteFields.length > 0,
)

const formUpdaterId = computed(() =>
  needsFormUpdater.value ? EnumFormUpdaterId.FormUpdaterUpdaterSearchAdvancedFilters : undefined,
)

const formUpdaterAdditionalParams = computed(() =>
  needsFormUpdater.value ? { entity: props.entity, ...props.filterUpdaterFields } : undefined,
)

// Sync the form's value with the parent's filter state and — for value
// updates that originated *outside* this form (cross-tab sync, taskbar
// restore, URL load) — ask the form updater to resolve any autocomplete
// IDs that aren't in the FormKit field's local option list yet.
//
// Distinguishing inside (user picked an option) from outside: compare the
// incoming value to the *form's current value*, not to the previous prop.
// Inside changes have already updated the form internally before reaching
// us via the parent → form already has the new value → nothing to do.
// Outside changes haven't touched the form yet → push the new value in and
// trigger the updater.
watch(
  () => props.filters,
  (updatedFilters, previousFilters) => {
    if (!formInstance.value || isEqual(updatedFilters, previousFilters)) return

    const formCurrentFilters = (formInstance.value.values?.filters ?? []) as FilterSelectorEntry[]
    if (isEqual(updatedFilters, formCurrentFilters)) return

    updateFieldValues({ filters: updatedFilters as FormFieldValue })

    if (!needsFormUpdater.value) return

    // `triggerFormUpdater()` builds its payload from `values.value`
    // synchronously, but the FormKit update from `updateFieldValues` lands
    // on the next microtask — without this wait, the request would carry
    // the stale form data and the backend wouldn't see the new IDs.
    nextTick(triggerFormUpdater)
  },
  { deep: true },
)

const onChanged = (fieldName: string, newValue: FormFieldValue) => {
  if (fieldName !== 'filters') return

  const changedFilters = Array.isArray(newValue) ? (newValue as FilterSelectorEntry[]) : []

  if (isEqual(changedFilters, props.filters)) return

  emit('filters-changed', props.entity, changedFilters)
}

defineExpose({
  // `entity` is exposed so the parent can pick the right instance out of the
  // v-for ref array (see SearchControls.getEntityFormInstance). Static value
  // is fine — each form's entity is fixed for its lifetime.
  entity: props.entity,
  resetFilters: () => formReset({ values: { filters: [] } }),
})
</script>

<template>
  <Form
    ref="form"
    :schema="schema"
    :form-updater-id="formUpdaterId"
    :form-updater-additional-params="formUpdaterAdditionalParams"
    form-updater-initial-only
    :initial-values="{ filters: filters as FormFieldValue }"
    @changed="onChanged"
  />
</template>
