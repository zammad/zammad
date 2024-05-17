// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type {
  FlatSelectOption,
  TreeSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'

const useFlatSelectOptions = (options?: Ref<TreeSelectOption[]>) => {
  const flattenOptions = (
    options: TreeSelectOption[],
    parents: SelectValue[] = [],
  ): FlatSelectOption[] =>
    options &&
    options.reduce(
      (flatOptions: FlatSelectOption[], { children, ...option }) => {
        flatOptions.push({
          ...option,
          parents,
          hasChildren: Boolean(children),
        })
        if (children)
          flatOptions.push(
            ...flattenOptions(children, [...parents, option.value]),
          )
        return flatOptions
      },
      [],
    )

  const flatOptions = computed(() => flattenOptions(options?.value || []))

  return {
    flatOptions,
    flattenOptions,
  }
}

export default useFlatSelectOptions
