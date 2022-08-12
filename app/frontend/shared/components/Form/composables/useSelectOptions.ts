// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef, ref, type Ref } from 'vue'
import { i18n } from '@shared/i18n'
import type { TicketState } from '@shared/entities/ticket/types'
import type { SelectOptionSorting, SelectOption } from '../fields/FieldSelect'
import type { FormFieldContext } from '../types/field'
import type { FlatSelectOption } from '../fields/FieldTreeSelect'
import type { AutoCompleteOption } from '../fields/FieldAutoComplete'
import useValue from './useValue'

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
  const dialog = ref(null)

  const { currentValue } = useValue(context)

  const hasStatusProperty = computed(
    () =>
      options.value &&
      options.value.some(
        (option) => (option as SelectOption | FlatSelectOption).status,
      ),
  )

  const translatedOptions = computed(
    () =>
      options.value &&
      options.value.map(
        (option: SelectOption | FlatSelectOption | AutoCompleteOption) =>
          ({
            ...option,
            label: context.value.noOptionsLabelTranslation
              ? option.label
              : i18n.t(option.label, option.labelPlaceholder as never),
            ...((option as AutoCompleteOption).heading
              ? {
                  heading: context.value.noOptionsLabelTranslation
                    ? (option as AutoCompleteOption).heading
                    : i18n.t(
                        (option as AutoCompleteOption).heading,
                        (option as AutoCompleteOption)
                          .headingPlaceholder as never,
                      ),
                }
              : {}),
          } as unknown as SelectOption | FlatSelectOption | AutoCompleteOption),
      ),
  )

  const optionValueLookup: ComputedRef<
    Record<
      string | number,
      SelectOption | FlatSelectOption | AutoCompleteOption
    >
  > = computed(
    () =>
      translatedOptions.value &&
      translatedOptions.value.reduce(
        (options, option) => ({
          ...options,
          [option.value]: option,
        }),
        {},
      ),
  )

  const sortedOptions = computed(() => {
    if (!context.value.sorting) return translatedOptions.value

    if (
      context.value.sorting !== 'label' &&
      context.value.sorting !== 'value'
    ) {
      console.warn(`Unsupported sorting option "${context.value.sorting}"`)
      return translatedOptions.value
    }

    return [...translatedOptions.value]?.sort((a, b) => {
      const aLabelOrValue =
        a[context.value.sorting as SelectOptionSorting] || a.value
      const bLabelOrValue =
        b[context.value.sorting as SelectOptionSorting] || b.value
      return aLabelOrValue.toString().localeCompare(bLabelOrValue.toString())
    })
  })

  const getSelectedOptionIcon = (selectedValue: string | number) =>
    optionValueLookup.value[selectedValue]?.icon as string

  const getSelectedOptionLabel = (selectedValue: string | number) =>
    optionValueLookup.value[selectedValue]?.label || selectedValue.toString()

  const getSelectedOptionStatus = (selectedValue: string | number) =>
    optionValueLookup.value[selectedValue] &&
    ((optionValueLookup.value[selectedValue] as SelectOption | FlatSelectOption)
      .status as TicketState)

  const selectOption = (
    option: SelectOption | FlatSelectOption | AutoCompleteOption,
  ) => {
    if (context.value.multiple) {
      const selectedValue = currentValue.value ?? []
      const optionIndex = selectedValue.indexOf(option.value)
      if (optionIndex !== -1) selectedValue.splice(optionIndex, 1)
      else selectedValue.push(option.value)
      selectedValue.sort(
        (a: string | number, b: string | number) =>
          sortedOptions.value.findIndex((option) => option.value === a) -
          sortedOptions.value.findIndex((option) => option.value === b),
      )
      context.value.node.input(selectedValue)
      return
    }

    context.value.node.input(option.value)
  }

  const getDialogFocusTargets = (optionsOnly?: boolean): HTMLElement[] => {
    const containerElement =
      dialog.value && (dialog.value as HTMLElement).parentElement
    if (!containerElement) return []

    const targetElements = Array.from(
      (containerElement as HTMLElement).querySelectorAll('[tabindex="0"]'),
    ) as HTMLElement[]
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
