<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { markRaw } from 'vue'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import { AutocompleteSearchKnowledgeBaseAnswerDocument } from '#desktop/entities/knowledge-base/graphql/queries/autocompleteSearch.api.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'

import FieldKnowledgeBaseAnswerOptionIcon from './FieldKnowledgeBaseAnswerOptionIcon.vue'

import type { AutoCompleteKnowledgeBaseAnswerOption } from './types.ts'
import type { AutoCompleteProps } from '../FieldAutoComplete/types.ts'

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteKnowledgeBaseAnswerOption[]
      // Called when the picker is dismissed (dropdown closed). Lets the caller
      // (e.g. the ticket sidebar) tear down the inline field.
      onDeactivate?: () => void
      // Answer translation IDs to omit from the results (e.g. answers already
      // linked to the ticket).
      exclude?: string[]
    }
  >
}

const props = defineProps<Props>()

// eslint-disable-next-line vue/no-mutating-props
Object.assign(props.context, {
  gqlQuery: AutocompleteSearchKnowledgeBaseAnswerDocument,
  // Read as a function so the exclusion list stays reactive across searches.
  additionalQueryParams: () => ({ exceptAnswerIds: props.context.exclude }),
  optionIconComponent: markRaw(FieldKnowledgeBaseAnswerOptionIcon),
  emptyInitialLabelText: __('Start typing to search…'),
})

const onCloseSelectDropdown = async () => {
  // Wait for a pending selection to commit before notifying the caller, so it
  // can tell "selected" apart from "dismissed".
  await props.context.node.settled

  props.context.onDeactivate?.()
}
</script>

<template>
  <FieldAutoCompleteInput
    :context="context"
    v-bind="$attrs"
    @close-select-dropdown="onCloseSelectDropdown"
  />
</template>
