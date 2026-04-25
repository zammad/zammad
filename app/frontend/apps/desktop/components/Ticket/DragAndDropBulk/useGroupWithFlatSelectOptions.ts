// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRef, type Ref } from 'vue'

import useFlatSelectOptions from '#shared/components/Form/fields/FieldTreeSelect/composables/useFlatSelectOptions.ts'
import type { FlatSelectOption } from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import useSelectOptions from '#shared/composables/useSelectOptions.ts'

export const useGroupWithFlatSelectOptions = (groupOptions: Ref<FlatSelectOption[]>) => {
  const { flatOptions } = useFlatSelectOptions(groupOptions)

  const { getSelectedOptionLabel, getSelectedOptionFullPath, getSelectedOptionParentsPath } =
    useSelectOptions<FlatSelectOption[]>(
      flatOptions,
      toRef({ multiple: true, noOptionsLabelTranslation: true }) as Ref<
        FormFieldContext<{ multiple?: boolean; noOptionsLabelTranslation: boolean }>
      >,
    )

  const lookupParentLabel = (parentId: ID | number) => {
    return flatOptions.value.find((option) => option.value === parentId)
  }

  return {
    lookupParentLabel,
    flatOptions,
    getSelectedOptionLabel,
    getSelectedOptionFullPath,
    getSelectedOptionParentsPath,
  }
}
