// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { computed, ref, type Ref } from 'vue'
import { i18n } from '@shared/i18n'
import { cloneDeep, keyBy } from 'lodash-es'
import type { TicketState } from '@shared/entities/ticket/types'
import type { SelectOptionSorting, SelectOption } from '../fields/FieldSelect'
import type { FormFieldContext } from '../types/field'
import type { FlatSelectOption } from '../fields/FieldTreeSelect'
import type { AutoCompleteOption } from '../fields/FieldAutoComplete'
import useValue from './useValue'
import type { SelectValue } from '../fields/FieldSelect/types'

const useSelectOptions = (
  options: Ref<SelectOption[] | FlatSelectOption[] | AutoCompleteOption[]>,
  context: Ref<
    FormFieldContext<{
      multiple?: boolean
      noOptionsLabelTranslation?: boolean
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

  const { currentValue } = useValue(context)

  const hasStatusProperty = computed(
    () =>
      options.value &&
      options.value.some(
        (option) => (option as SelectOption | FlatSelectOption).status,
      ),
  )

  const translatedOptions = computed(() => {
    if (!options.value) return []

    const { noOptionsLabelTranslation } = context.value

    return options.value.map(
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
    return option?.label || selectedValue.toString()
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
  }
}

export default useSelectOptions
