// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { email as emailValidation } from '@formkit/rules'
import { ref, type Ref } from 'vue'

import type { DropdownOptionsAction } from '#desktop/components/CommonSelect/types.ts'
import type {
  AutoCompleteOptionValueDictionary,
  SelectOptionFunction,
} from '#desktop/components/Form/fields/FieldAutoComplete/types.ts'

import type { FormKitNode } from '@formkit/core'

export const emailFilterValueValidator = (filter: string) =>
  emailValidation({ value: filter } as FormKitNode)

export const phoneFilterValueValidator = (filter: string) =>
  /^\+?[1-9]\d+$/.test(filter)

export const useAddUnknownValueAction = (
  label?: Ref<string>,
  filterValueValidator?: (filter: string) => boolean | Promise<boolean>,
) => {
  const actions = ref<DropdownOptionsAction[]>([])
  const actionLabel = label ?? ref(__('add new email address'))

  const isValidFilterValue = filterValueValidator ?? emailFilterValueValidator

  const isNewOption = (
    filter: string,
    optionValues: AutoCompleteOptionValueDictionary,
  ) => !optionValues[filter]

  const addUnknownValue = (
    filter: string,
    selectOption: SelectOptionFunction,
    focus: boolean,
  ) => {
    const newOption = {
      value: filter,
      label: filter,
    }

    selectOption(newOption, focus)
  }

  const onSearchInteractionUpdate = (
    filter: string,
    optionValues: AutoCompleteOptionValueDictionary,
    selectOption: SelectOptionFunction,
  ) => {
    if (!isNewOption(filter, optionValues) || !isValidFilterValue(filter)) {
      actions.value = []
      return
    }

    actions.value = [
      {
        key: 'addUnknownValue',
        label: actionLabel.value,
        icon: 'plus-square-fill',
        onClick: (focus) => {
          addUnknownValue(filter, selectOption, focus)

          // Reset actions after current filter was added.
          actions.value = []
        },
      },
    ]
  }

  return {
    actions,
    isNewOption,
    isValidFilterValue,
    addUnknownValue,
    onSearchInteractionUpdate,
  }
}
