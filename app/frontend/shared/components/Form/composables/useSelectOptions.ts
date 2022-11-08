// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type Ref, watch } from 'vue'
import { i18n } from '@shared/i18n'
import { cloneDeep, keyBy } from 'lodash-es'
import type { TicketState } from '@shared/entities/ticket/types'
import type {
  SelectOptionSorting,
  SelectOption,
  SelectValue,
} from '../fields/FieldSelect'
import type { FormFieldContext } from '../types/field'
import type { FlatSelectOption } from '../fields/FieldTreeSelect'
import type { AutoCompleteOption } from '../fields/FieldAutoComplete'
import useValue from './useValue'

const useSelectOptions = (
  options: Ref<SelectOption[] | FlatSelectOption[] | AutoCompleteOption[]>,
  context: Ref<
    FormFieldContext<{
      historicalOptions?: Record<string, string>
      multiple?: boolean
      noOptionsLabelTranslation?: boolean
      rejectNonExistentValues?: boolean
      sorting?: SelectOptionSorting
    }>
  >,
  arrowLeftCallback?: (
    option?: SelectOption | FlatSelectOption | AutoCompleteOption,
    getDialogFocusTargets?: (optionsOnly?: boolean) => HTMLElement[],
  ) => void,
  arrowRightCallback?: (
    option?: SelectOption | FlatSelectOption | AutoCompleteOption,
    getDialogFocusTargets?: (optionsOnly?: boolean) => HTMLElement[],
  ) => void,
) => {
  const dialog = ref<HTMLElement>()

  const { currentValue, hasValue, valueContainer, clearValue } =
    useValue(context)

  const appendedOptions: Ref<
    SelectOption[] | FlatSelectOption[] | AutoCompleteOption[]
  > = ref([])

  const availableOptions = computed(() => [
    ...(options.value || []),
    ...appendedOptions.value,
  ])

  const hasStatusProperty = computed(() =>
    availableOptions.value?.some(
      (option) => (option as SelectOption | FlatSelectOption).status,
    ),
  )

  const translatedOptions = computed(() => {
    if (!availableOptions.value) return []

    const { noOptionsLabelTranslation } = context.value

    return availableOptions.value.map(
      (option: SelectOption | FlatSelectOption | AutoCompleteOption) => {
        const label = noOptionsLabelTranslation
          ? option.label
          : i18n.t(option.label, ...(option.labelPlaceholder || []))

        const variant = option as AutoCompleteOption
        const heading = noOptionsLabelTranslation
          ? variant.heading
          : i18n.t(variant.heading, ...(variant.headingPlaceholder || []))

        return {
          ...option,
          label,
          heading,
        } as SelectOption | FlatSelectOption | AutoCompleteOption
      },
    )
  })

  const optionValueLookup = computed(() =>
    keyBy(translatedOptions.value, 'value'),
  )

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

  const getSelectedOptionIcon = (selectedValue: SelectValue) => {
    const key = selectedValue.toString()
    const option = optionValueLookup.value[key]
    return option?.icon as string
  }

  const getSelectedOptionLabel = (selectedValue: SelectValue) => {
    const key = selectedValue.toString()
    const option = optionValueLookup.value[key]
    return option?.label
  }

  const getSelectedOptionStatus = (selectedValue: SelectValue) => {
    const key = selectedValue.toString()
    const option = optionValueLookup.value[key] as
      | SelectOption
      | FlatSelectOption
    return option?.status as TicketState
  }

  const selectOption = (
    option: SelectOption | FlatSelectOption | AutoCompleteOption,
  ) => {
    if (context.value.multiple) {
      const selectedValues = cloneDeep(currentValue.value) || []
      const optionIndex = selectedValues.indexOf(option.value)
      if (optionIndex !== -1) selectedValues.splice(optionIndex, 1)
      else selectedValues.push(option.value)
      selectedValues.sort(
        (a: string | number, b: string | number) =>
          sortedOptions.value.findIndex((option) => option.value === a) -
          sortedOptions.value.findIndex((option) => option.value === b),
      )
      context.value.node.input(selectedValues)
      return
    }

    context.value.node.input(option.value)
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
        (targetElement) =>
          targetElement.attributes.getNamedItem('role')?.value === 'option',
      )

    return targetElements
  }

  const advanceDialogFocus = (
    event: KeyboardEvent,
    option?: SelectOption | FlatSelectOption,
  ) => {
    const originElement = event.target as HTMLElement

    const targetElements = getDialogFocusTargets()
    if (!targetElements.length) return

    const originElementIndex =
      targetElements.indexOf(
        (document.activeElement as HTMLElement) || originElement,
      ) || 0

    let targetElement

    switch (event.key) {
      case 'ArrowLeft':
        if (typeof arrowLeftCallback === 'function')
          arrowLeftCallback(option, getDialogFocusTargets)
        break
      case 'ArrowUp':
        targetElement =
          targetElements[originElementIndex - 1] ||
          targetElements[targetElements.length - 1]
        break
      case 'ArrowRight':
        if (typeof arrowRightCallback === 'function')
          arrowRightCallback(option, getDialogFocusTargets)
        break
      case 'ArrowDown':
        targetElement =
          targetElements[originElementIndex + 1] || targetElements[0]
        break
      default:
    }

    if (targetElement) targetElement.focus()
  }

  // Setup a mechanism to handle missing options, including:
  //   - appending historical options for current values
  //   - clearing value in case options are missing
  const setupMissingOptionHandling = () => {
    const historicalOptions = context.value.historicalOptions || {}

    // Append historical options to the list of available options, if:
    //   - non-existent values are not supposed to be rejected
    //   - we have a current value
    //   - we have a list of historical options
    if (
      !context.value.rejectNonExistentValues &&
      hasValue.value &&
      historicalOptions
    ) {
      appendedOptions.value = valueContainer.value.reduce(
        (
          accumulator:
            | SelectOption[]
            | FlatSelectOption[]
            | AutoCompleteOption[],
          value: SelectValue,
        ) => [
          ...accumulator,

          // Make sure the options are not duplicated!
          ...(!options.value.some((option) => option.value === value) &&
          historicalOptions[value.toString()]
            ? [
                {
                  value,
                  label: historicalOptions[value.toString()],
                },
              ]
            : []),
        ],
        [],
      )
    }

    // Reject non-existent values during the initialization phase.
    //   Note that this behavior is controlled by a dedicated flag.
    if (
      context.value.rejectNonExistentValues &&
      hasValue.value &&
      typeof optionValueLookup.value[currentValue.value] === 'undefined'
    )
      clearValue()

    // Set up a watcher that clears a missing option value on subsequent mutations of the options prop.
    //   In this case, the dedicated flag is ignored.
    watch(
      () => options.value,
      () => {
        if (
          !hasValue.value ||
          typeof optionValueLookup.value[currentValue.value] !== 'undefined'
        )
          return

        clearValue()
      },
    )
  }

  return {
    dialog,
    hasStatusProperty,
    translatedOptions,
    optionValueLookup,
    sortedOptions,
    getSelectedOptionIcon,
    getSelectedOptionLabel,
    getSelectedOptionStatus,
    selectOption,
    getDialogFocusTargets,
    advanceDialogFocus,
    setupMissingOptionHandling,
  }
}

export default useSelectOptions
