<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { computed, defineAsyncComponent } from 'vue'
import FieldCustomerOptionIcon from './FieldCustomerOptionIcon.vue'
import type { AutoCompleteProps } from '../FieldAutoComplete/types'
import type { FormFieldContext } from '../../types/field'
import type { AutoCompleteCustomerOption } from './types'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '@shared/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteCustomerOption[]
    }
  >
}

const props = defineProps<Props>()

const context = computed(() => ({
  ...props.context,
  optionIconComponent: FieldCustomerOptionIcon,

  // TODO: change the action to the actual new customer route
  action: '/tickets',
  actionIcon: 'new-customer',

  // TODO: change the query to the actual autocomplete search of customers
  gqlQuery: `
query autocompleteSearchCustomer($query: String!, $limit: Int) {
  autocompleteSearchCustomer(query: $query, limit: $limit) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    user
  }
}
`,
}))
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
