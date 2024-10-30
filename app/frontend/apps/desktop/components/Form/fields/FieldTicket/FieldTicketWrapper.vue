<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw } from 'vue'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { AutocompleteSearchTicketDocument } from '#shared/entities/ticket/graphql/queries/autocompleteSearchTicket.api.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

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

const { config } = useApplicationStore()

Object.assign(props.context, {
  optionIconComponent: markRaw(FieldTicketOptionIcon),
  gqlQuery: AutocompleteSearchTicketDocument,
  additionalQueryParams: {
    exceptTicketInternalId: props.context.exceptTicketInternalId,
  },
  filterInputPlaceholder: __('Ticket number or title'),
  // Currently it seems to be the search finds not the ticket with the complete ticket hook and number (e.g. Ticket#123456).
  stripFilter: (filter: string) => filter.replace(config.ticket_hook, ''),
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
