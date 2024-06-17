<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { computed } from 'vue'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import FieldAutoCompleteInput from '../FieldAutoComplete/FieldAutoCompleteInput.vue'
import {
  emailFilterValueValidator,
  phoneFilterValueValidator,
  useAddUnknownValueAction,
} from '../FieldAutoComplete/useAddUnknownValueAction.ts'

import type { AutoCompleteProps } from '../FieldAutoComplete/types.ts'

interface Props {
  context: FormFieldContext<AutoCompleteProps>
}

const props = defineProps<Props>()

const { contact } = props.context

const actionLabel = computed(() =>
  contact === 'phone'
    ? __('add new phone number')
    : __('add new email address'),
)

const filterValueValidator = (filter: string) => {
  switch (contact) {
    case 'phone':
      return phoneFilterValueValidator(filter)
    case 'email':
    default:
      return emailFilterValueValidator(filter)
  }
}

const { actions, onSearchInteractionUpdate, onKeydownFilterInput } =
  useAddUnknownValueAction(actionLabel, filterValueValidator)

Object.assign(props.context, {
  actions,
  emptyInitialLabelText:
    contact === 'phone'
      ? __('Start typing to search or enter a phone number…')
      : __('Start typing to search or enter an email address…'),
})
</script>

<template>
  <FieldAutoCompleteInput
    :context="context"
    v-bind="$attrs"
    @search-interaction-update="onSearchInteractionUpdate"
    @keydown-filter-input="onKeydownFilterInput"
  />
</template>
