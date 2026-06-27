// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep, keyBy } from 'lodash-es'
import { computed, ref, type Ref, watch } from 'vue'

import type { SelectOption, SelectValue } from '#shared/components/CommonSelect/types.ts'
import useValue from '#shared/components/Form/composables/useValue.ts'
import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutocomplete/types'
import type { SelectOptionSorting } from '#shared/components/Form/fields/FieldSelect/types.ts'
import type {
  FlatSelectOption,
  TreeSelectOption,
} from '#shared/components/Form/fields/FieldTreeSelect/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { i18n } from '#shared/i18n.ts'

type AllowedSelectValue = SelectValue | Record<string, unknown>

const useSelectOptions = <T extends SelectOption[] | FlatSelectOption[] | AutoCompleteOption[]>(
  options: Ref<T>,
  context: Ref<
    FormFieldContext<{
      historicalOptions?: Record<string, string>
      multiple?: boolean
      noOptionsLabelTranslation?: boolean
      rejectNonExistentValues?: boolean
      sorting?: SelectOptionSorting
      complexValue?: boolean
    }>
  >,
  appendedTreeOptions?: Ref<TreeSelectOption[]>,
) => {
  const dialog = ref<HTMLElement>()

  const { currentValue, hasValue, valueContainer, clearValue } = useValue(context)

  const appendedOptions = ref<T>([] as unknown as T)

  const availableOptions = computed(() => [...(options.value || []), ...appendedOptions.value])

  const hasStatusProperty = computed(() =>
    availableOptions.value?.some((option) => (option as SelectOption | FlatSelectOption).status),
  )

  const translatedOptions = computed(() => {
    if (!availableOptions.value) return []

    const { noOptionsLabelTranslation } = context.value

    return availableOptions.value.map((option) => {
      const label =
        noOptionsLabelTranslation && !option.labelPlaceholder
          ? option.label || ''
          : i18n.t(option.label, ...(option.labelPlaceholder || []))

      const variant = option as AutoCompleteOption
      const heading =
        noOptionsLabelTranslation && !variant.headingPlaceholder
          ? variant.heading || ''
          : i18n.t(variant.heading, ...(variant.headingPlaceholder || []))

      return Object.assign(option, {
        label,
        heading,
      })
    })
  })

  const optionValueLookup = computed(() => keyBy(translatedOptions.value, 'value'))

  const sortedOptions = computed(() => {
    const { sorting } = context.value

    if (!sorting) return translatedOptions.value

    if (sorting !== 'label' && sorting !== 'value') {
      console.warn(`Unsupported sorting option "${sorting}"`)
      return translatedOptions.value
    }

    return [...translatedOptions.value]?.sort((a, b) => {
      const aLabelOrValue = a[sorting] || a.value
      const bLabelOrValue = b[sorting] || a.value
      return String(aLabelOrValue).localeCompare(String(bLabelOrValue))
    })
  })

  const getSelectedOption = (selectedValue: AllowedSelectValue): T[number] => {
    if (typeof selectedValue === 'object' && selectedValue !== null)
      return selectedValue as unknown as T[number]
    const key = selectedValue.toString()
    return optionValueLookup.value[key]
  }

  const getSelectedOptionIcon = (selectedValue: AllowedSelectValue) => {
    const option = getSelectedOption(selectedValue)
    return option?.icon as string
  }

  const getSelectedOptionValue = (selectedValue: AllowedSelectValue) => {
    if (typeof selectedValue !== 'object') return selectedValue
    const option = getSelectedOption(selectedValue)
    return option?.value
  }

  const getSelectedOptionLabel = (selectedValue: AllowedSelectValue) => {
    const option = getSelectedOption(selectedValue)
    return option?.label
  }

  const getSelectedOptionStatus = (selectedValue: AllowedSelectValue) => {
    const option = getSelectedOption(selectedValue) as SelectOption | FlatSelectOption
    return option?.status
  }

  const getSelectedOptionParents = (selectedValue: string | number): SelectValue[] =>
    (optionValueLookup.value[selectedValue] &&
      (optionValueLookup.value[selectedValue] as FlatSelectOption).parents) ||
    []

  const getSelectedOptionParentsPath = (selectedValue: string | number) =>
    getSelectedOptionParents(selectedValue)
      .map((parentValue) => `${getSelectedOptionLabel(parentValue)} \u203A `)
      .join('')

  const getSelectedOptionFullPath = (selectedValue: string | number) =>
    getSelectedOptionParentsPath(selectedValue) +
    (getSelectedOptionLabel(selectedValue) || i18n.t('%s (unknown)', selectedValue.toString()))

  const valueBuilder = (option: SelectOption): AllowedSelectValue => {
    return context.value.complexValue ? { value: option.value, label: option.label } : option.value
  }

  const selectOption = (option: T extends Array<infer V> ? V : never) => {
    if (!context.value.multiple) {
      context.value.node.input(valueBuilder(option))
      return
    }

    const selectedValues = cloneDeep(currentValue.value) || []

    const optionIndex = selectedValues.findIndex((selectedValue: AllowedSelectValue) => {
      if (typeof selectedValue === 'object' && selectedValue !== null && 'value' in selectedValue) {
        return selectedValue.value === option.value
      }

      return selectedValue === option.value
    })

    if (optionIndex !== -1) selectedValues.splice(optionIndex, 1)
    else selectedValues.push(valueBuilder(option))

    selectedValues.sort(
      (a: AllowedSelectValue, b: AllowedSelectValue) =>
        sortedOptions.value.findIndex((option) => {
          if (typeof a === 'object' && a !== null && 'value' in a) {
            return a.value === option.value
          }

          return a === option.value
        }) -
        sortedOptions.value.findIndex((option) => {
          if (typeof b === 'object' && b !== null && 'value' in b) {
            return b.value === option.value
          }

          return b === option.value
        }),
    )

    context.value.node.input(selectedValues)
  }

  const getDialogFocusTargets = (optionsOnly?: boolean): HTMLElement[] => {
    const containerElement = dialog.value?.parentElement
    if (!containerElement) return []

    const targetElements = Array.from(
      containerElement.querySelectorAll<HTMLElement>('[tabindex="0"]'),
    )
    if (!targetElements) return []

    if (optionsOnly)
      return targetElements.filter(
        (targetElement) => targetElement.attributes.getNamedItem('role')?.value === 'option',
      )

    return targetElements
  }

  const handleValuesForNonExistingOrDisabledOptions = (rejectNonExistentValues?: boolean) => {
    if (!hasValue.value || context.value.pendingValueUpdate) return

    const localRejectNonExistentValues = rejectNonExistentValues ?? true

    if (context.value.multiple) {
      const availableValues = currentValue.value.filter((selectValue: string | number) => {
        const selectValueOption = optionValueLookup.value[selectValue]
        return (
          (localRejectNonExistentValues &&
            typeof selectValueOption !== 'undefined' &&
            selectValueOption?.disabled !== true) ||
          (!localRejectNonExistentValues && selectValueOption?.disabled !== true)
        )
      }) as SelectValue[]

      if (availableValues.length !== currentValue.value.length) {
        context.value.node.input(availableValues, false)
      }

      return
    }

    const currentValueOption = optionValueLookup.value[currentValue.value]
    if (
      (localRejectNonExistentValues && typeof currentValueOption === 'undefined') ||
      currentValueOption?.disabled
    )
      clearValue(false)
  }

  // Setup a mechanism to handle missing and disabled options, including:
  //   - appending historical options for current values
  //   - clearing value in case options are missing
  const setupMissingOrDisabledOptionHandling = () => {
    const { historicalOptions } = context.value

    // When we are in a "create" form situation and no 'rejectNonExistentValues' flag
    // is given, it should be activated.
    if (context.value.rejectNonExistentValues === undefined) {
      const rootNode = context.value.node.at('$root')
      context.value.rejectNonExistentValues =
        rootNode &&
        rootNode.name !== context.value.node.name &&
        !rootNode.context?.initialEntityObject
    }

    // Remember current optionValueLookup in node context.
    context.value.optionValueLookup = optionValueLookup

    // Navigate and insert into tree structure, parsing hierarchical values like "Example::Level1::Deeper"
    const appendToTree = (value: SelectValue, label: string | undefined): void => {
      if (!appendedTreeOptions) return

      if (typeof value !== 'string' || !value.includes('::') || !label) {
        appendedTreeOptions.value.push({ value, label })
        return
      }

      // Split into parts and navigate/create tree structure
      const parts = value.split('::')
      let currentLevel = appendedTreeOptions.value

      // Navigate through parent nodes, creating them if needed
      for (let i = 0; i < parts.length - 1; i++) {
        const parentValue = parts.slice(0, i + 1).join('::')
        const parentLabel = parts[i]

        // Find or create parent node
        let parentNode = currentLevel.find((opt) => opt.value === parentValue)
        if (!parentNode) {
          parentNode = { value: parentValue, label: parentLabel, children: [] }
          currentLevel.push(parentNode)
        }

        // Ensure children array exists
        if (!parentNode.children) {
          parentNode.children = []
        }

        // Move to next level
        currentLevel = parentNode.children
      }

      // Add the final leaf node
      currentLevel.push({ value, label })
    }

    // Add helper function to allow features to dynamically add missing options
    context.value.addMissingOption = (value: SelectValue, label?: string): void => {
      // Check if option already exists to prevent duplicates
      if (optionValueLookup.value[value.toString()] !== undefined) {
        return
      }

      // Tree select: auto-parse hierarchical values (e.g., "Support::L2::Incident")
      if (appendedTreeOptions) {
        appendToTree(value as string, label)
        return
      }

      // Flat select: simple append
      appendedOptions.value.push({ value, label } as T[number])
    }

    // Remove a previously appended missing option by value (counterpart to addMissingOption).
    context.value.removeMissingOption = (value: SelectValue): void => {
      if (appendedTreeOptions) {
        // Remove the value from the tree, pruning parent nodes that become childless.
        const removeFromTree = (nodes: TreeSelectOption[]): TreeSelectOption[] =>
          nodes.reduce<TreeSelectOption[]>((result, opt) => {
            const filteredChildren = opt.children ? removeFromTree(opt.children) : undefined

            if (opt.value === value && (!filteredChildren || filteredChildren.length === 0)) {
              return result
            }

            result.push({ ...opt, children: filteredChildren })
            return result
          }, [])

        appendedTreeOptions.value = removeFromTree(appendedTreeOptions.value)
        return
      }

      appendedOptions.value = appendedOptions.value.filter(
        (opt: SelectOption | FlatSelectOption) => opt.value !== value,
      ) as T
    }

    // TODO: Workaround for empty string, because currently the "nulloption" exists also for multiselect fields (#4513).
    if (context.value.multiple) {
      watch(
        () =>
          hasValue.value &&
          valueContainer.value.includes('') &&
          context.value.clearable &&
          !options.value.some((option) => option.value === ''),
        () => {
          const emptyOption: SelectOption = {
            value: '',
            label: '-',
          }

          ;(appendedOptions.value as SelectOption[]).unshift(emptyOption)
        },
      )
    }

    // Append historical options to the list of available options, if:
    //   - non-existent values are not supposed to be rejected
    //   - we have a current value
    //   - we have a list of historical options
    if (!context.value.rejectNonExistentValues && hasValue.value) {
      if (appendedTreeOptions) {
        // Tree select mode: always append unknown values (label from historicalOptions or undefined)
        valueContainer.value.forEach((value: SelectValue) => {
          if (optionValueLookup.value[value.toString()] === undefined) {
            const label = historicalOptions?.[value.toString()]

            appendToTree(value, label)
          }
        })
      } else {
        // Flat select mode: build options array using reduce
        appendedOptions.value = valueContainer.value.reduce(
          (accumulator: SelectOption[], value: SelectValue) => {
            if (optionValueLookup.value[value.toString()] !== undefined) {
              return accumulator
            }

            // TODO: Workaround, because currently the "nulloption" exists also for multiselect fields (#4513).
            if (context.value.multiple && value === '') {
              accumulator.unshift({ value, label: '-' })
              return accumulator
            }

            const label = historicalOptions?.[value.toString()]
            accumulator.push({ value, label })

            return accumulator
          },
          [],
        )
      }
    }

    // Reject non-existent or disabled option values during the initialization phase (note that
    //  the non-existent values behavior is controlled by a dedicated flag).
    handleValuesForNonExistingOrDisabledOptions(context.value.rejectNonExistentValues)

    // Set up a watcher that clears a missing option value or disabled options on subsequent mutations
    //  of the options prop (in this case, the dedicated "rejectNonExistentValues" flag is ignored).
    watch(options, () => handleValuesForNonExistingOrDisabledOptions())

    // Remove appended options that now exist in real options (to prevent duplicates after formUpdater).
    // For the tree select situation we are handling this in the "useFlatSelectOptions" composable, because here we have
    // the easier the base tree structure available, which we need for the correct handling.
    watch(options, (newOptions) => {
      if (!newOptions) return

      if (appendedOptions.value.length > 0) {
        appendedOptions.value = appendedOptions.value.filter(
          (appendedOpt: SelectOption | FlatSelectOption) =>
            !newOptions.some((opt) => opt.value === appendedOpt.value),
        )
      }
    })
  }

  return {
    dialog,
    hasStatusProperty,
    translatedOptions,
    optionValueLookup,
    sortedOptions,
    getSelectedOption,
    getSelectedOptionValue,
    getSelectedOptionIcon,
    getSelectedOptionLabel,
    getSelectedOptionStatus,
    getSelectedOptionParents,
    getSelectedOptionParentsPath,
    getSelectedOptionFullPath,
    selectOption,
    getDialogFocusTargets,
    setupMissingOrDisabledOptionHandling,
    appendedOptions,
  }
}

export default useSelectOptions
