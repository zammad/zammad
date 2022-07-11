<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import FieldOrganizationOptionIcon from './FieldOrganizationOptionIcon.vue'
import type { AutoCompleteProps } from '../FieldAutoComplete/types'
import type { AutoCompleteOrganizationOption } from './types'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '@shared/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteOrganizationOption[]
    }
  >
}

const props = defineProps<Props>()

const context = computed(() => ({
  ...props.context,
  optionIconComponent: FieldOrganizationOptionIcon,

  // TODO: change the action to the actual new organization route
  action: '/tickets',
  actionIcon: 'new-organization',

  // TODO: change the query to the actual autocomplete search of organizations
  gqlQuery: `
query autocompleteSearchOrganization($query: String!, $limit: Int) {
  autocompleteSearchOrganization(query: $query, limit: $limit) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    organization
  }
}
`,
}))
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>

<style lang="scss">
.field-organization {
  &.floating-input:focus-within:not([data-populated]) {
    label {
      @apply translate-y-0 translate-x-0 scale-100 opacity-100;
    }
  }

  .formkit-label {
    @apply py-4;
  }
}
</style>
