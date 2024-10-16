<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw } from 'vue'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { AutocompleteSearchTicketDocument } from '#shared/entities/ticket/graphql/queries/autocompleteSearchTicket.api.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'

import FieldTicketOptionIcon from './FieldTicketOptionIcon.vue'

import type { AutoCompleteTicketOption } from './types'
import type { AutoCompleteProps } from '../FieldAutoComplete/types.ts'

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteTicketOption[]
      exceptTicketInternalId?: number
    }
  >
}

const props = defineProps<Props>()

Object.assign(props.context, {
  optionIconComponent: markRaw(FieldTicketOptionIcon),
  gqlQuery: AutocompleteSearchTicketDocument,
  additionalQueryParams: {
    exceptTicketInternalId: props.context.exceptTicketInternalId,
  },
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
