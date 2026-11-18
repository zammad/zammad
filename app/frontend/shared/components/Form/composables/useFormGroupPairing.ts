// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useMutationObserver, useResizeObserver } from '@vueuse/core'
import { onMounted, shallowRef, toValue, watch, type MaybeRefOrGetter, type ShallowRef } from 'vue'

const UNPAIRED_FIELD_ATTRIBUTE = 'data-form-group-unpaired'

const SINGLE_COLUMN_FIELD_CLASS = 'form-group-single-column'

// Marks the half-size fields of a two-column form group which have no half-size partner in their row, so that they
//  can span both columns. Pairing follows the grid's auto placement: it restarts after every full-width child.
//  Fields sized manually to one column count as partners, but keep their own size.
export const useFormGroupPairing = (
  container: Readonly<ShallowRef<HTMLElement | null>>,
  allFieldsHalfSize: MaybeRefOrGetter<boolean | undefined>,
) => {
  // The span of configured fields depends on the mark itself, so only manually sized fields are measured. Their
  //  rendered width follows whatever placement and responsive variant of their classes is active.
  const isHalfSize = (element: Element, groupWidth: number) =>
    toValue(allFieldsHalfSize) ||
    element.classList.contains(SINGLE_COLUMN_FIELD_CLASS) ||
    element.getBoundingClientRect().width < groupWidth

  const children = shallowRef<HTMLElement[]>([])

  const markUnpairedFields = () => {
    const groupWidth = container.value?.getBoundingClientRect().width ?? 0
    const unpairedFields = new Set<Element>()
    let fieldWithoutPartner: Element | undefined

    children.value.forEach((element) => {
      // Fields hidden by a core workflow and hidden inputs stay in the DOM, but take no place in the grid.
      if (element.matches('.hidden, input[type="hidden"]')) return

      if (!isHalfSize(element, groupWidth)) {
        if (fieldWithoutPartner) unpairedFields.add(fieldWithoutPartner)
        fieldWithoutPartner = undefined
        return
      }

      fieldWithoutPartner = fieldWithoutPartner ? undefined : element
    })

    if (fieldWithoutPartner) unpairedFields.add(fieldWithoutPartner)

    children.value.forEach((element) => {
      element.toggleAttribute(UNPAIRED_FIELD_ATTRIBUTE, unpairedFields.has(element))
    })
  }

  const updateChildren = () => {
    children.value = Array.from(container.value?.children ?? []) as HTMLElement[]
    markUnpairedFields()
  }

  // Only the children of the group and their class are watched, changes inside a field (e.g. typing in the editor) do
  //  not move it in the grid.
  useMutationObserver(container, updateChildren, { childList: true })
  useMutationObserver(children, markUnpairedFields, { attributeFilter: ['class'] })
  // The group class sizes all fields, the computed span is only right once it is updated.
  watch(() => toValue(allFieldsHalfSize), markUnpairedFields, { flush: 'post' })

  // The group is its own size container, crossing one of its breakpoints can change the span of manually sized fields.
  useResizeObserver(container, markUnpairedFields)

  onMounted(updateChildren)
}
