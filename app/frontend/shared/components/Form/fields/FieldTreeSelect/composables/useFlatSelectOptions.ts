// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, watch, type Ref } from 'vue'

import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import type {
  FlatSelectOption,
  TreeSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'

const useFlatSelectOptions = (options?: Ref<TreeSelectOption[]>) => {
  const appendedTreeOptions = ref<TreeSelectOption[]>([])

  const flattenOptions = (
    options: TreeSelectOption[],
    parents: SelectValue[] = [],
  ): FlatSelectOption[] =>
    options &&
    options.reduce((flatOptions: FlatSelectOption[], { children, ...option }) => {
      flatOptions.push({
        ...option,
        parents,
        hasChildren: Boolean(children),
      })
      if (children) flatOptions.push(...flattenOptions(children, [...parents, option.value]))
      return flatOptions
    }, [])

  const mergeTreeOptions = (
    base: TreeSelectOption[],
    appended: TreeSelectOption[],
  ): TreeSelectOption[] => {
    const valueMap = new Map(base.map((opt, idx) => [opt.value, idx]))
    const merged = [...base]

    appended.forEach((appendedOption) => {
      const existingIndex = valueMap.get(appendedOption.value)

      if (existingIndex !== undefined) {
        // Option exists - merge children recursively if both have them.
        const existing = merged[existingIndex]

        if (appendedOption.children) {
          existing.children = mergeTreeOptions(existing.children || [], appendedOption.children)
        }
      } else {
        // New option - add to merged array and update map.
        merged.push(appendedOption)
        valueMap.set(appendedOption.value, merged.length - 1)
      }
    })

    return merged
  }

  // Remove appended tree options that now exist in the base options (e.g. after formUpdater provides them).
  // This must happen here (not in useSelectOptions) because there the watched `options` ref is the
  // already-merged flatOptions, which would incorrectly match everything.
  if (options) {
    watch(options, (newBaseOptions) => {
      if (!newBaseOptions || appendedTreeOptions.value.length === 0) return

      const collectValues = (opts: TreeSelectOption[]): SelectValue[] =>
        opts.flatMap((opt) => [opt.value, ...(opt.children ? collectValues(opt.children) : [])])

      const baseOptionValues = new Set(collectValues(newBaseOptions))

      // Filter children first, then only remove a node if its value exists
      // in base AND it has no remaining children (preserves parent structure
      // needed for newly appended nested children).
      const filterTree = (nodes: TreeSelectOption[]): TreeSelectOption[] =>
        nodes.reduce<TreeSelectOption[]>((result, opt) => {
          const filteredChildren = opt.children ? filterTree(opt.children) : undefined

          if (
            baseOptionValues.has(opt.value) &&
            (!filteredChildren || filteredChildren.length === 0)
          ) {
            return result
          }

          result.push({ ...opt, children: filteredChildren })
          return result
        }, [])

      appendedTreeOptions.value = filterTree(appendedTreeOptions.value)
    })
  }

  // There needs to be a deep merge of the current options and the appended tree options, because otherwise the deep options
  // are missing in the flat options. For this we creating an reference which can then be used inside our normal use select options
  // handling, because we have not only the simple appended options possibility.
  const flatOptions = computed(() => {
    const baseOptions = options?.value || []
    const appendedOptions = appendedTreeOptions.value

    if (appendedOptions.length === 0) {
      return flattenOptions(baseOptions)
    }

    const mergedTree = mergeTreeOptions(baseOptions, appendedOptions)
    return flattenOptions(mergedTree)
  })

  return {
    flatOptions,
    flattenOptions,
    appendedTreeOptions,
  }
}

export default useFlatSelectOptions
