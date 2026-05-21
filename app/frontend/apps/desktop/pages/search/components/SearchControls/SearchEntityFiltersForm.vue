<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, useTemplateRef, watch, type Ref } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormRef, FormSchemaField, FormFieldValue } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { EnumFormUpdaterId } from '#shared/graphql/types.ts'

import type { FilterSelectorEntry } from '#desktop/components/Form/fields/FieldFilterSelector/types.ts'
import type { FilterSelectorEntityOverride } from '#desktop/components/Search/types.ts'

interface FilterRelationField {
  name: string
  relation: string
}

interface Props {
  entity: string
  filters?: FilterSelectorEntry[]
  filterAttributes?: FilterAttribute[]
  filterAttributesOverride?: FilterSelectorEntityOverride[]
  filterRelationFields?: FilterRelationField[]
}

const props = withDefaults(defineProps<Props>(), {
  filters: () => [],
  filterAttributes: () => [],
  filterRelationFields: () => [],
})

const emit = defineEmits<{
  'filters-changed': [entity: string, value: FilterSelectorEntry[]]
}>()

const formInstance = useTemplateRef('form')

const { updateFieldValues, formReset } = useForm(formInstance as Ref<FormRef>)

const schema = computed<FormSchemaField[]>(() => [
  {
    type: 'filterSelector',
    name: 'filters',
    props: {
      filterAttributes: props.filterAttributes,
      filterAttributesOverride: props.filterAttributesOverride,
    },
  },
])

// Wire up the form updater only when the entity has relation-typed filter
// attributes that need server-resolved options. Entities like Organization
// have only static filter fields (matches on plain text), so the form
// updater would just emit empty roundtrips.
const hasRelationFields = computed(() => props.filterRelationFields.length > 0)

const formUpdaterId = computed(() =>
  hasRelationFields.value ? EnumFormUpdaterId.FormUpdaterUpdaterSearchAdvancedFilters : undefined,
)

const formUpdaterAdditionalParams = computed(() =>
  hasRelationFields.value
    ? { entity: props.entity, filterRelationFields: props.filterRelationFields }
    : undefined,
)

watch(
  () => props.filters,
  (updatedFilters, previousFilters) => {
    if (!formInstance.value || isEqual(updatedFilters, previousFilters)) return

    updateFieldValues({
      filters: updatedFilters as FormFieldValue,
    })
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
