// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useElementBounding, useElementVisibility, useWindowSize } from '@vueuse/core'
import { computed, nextTick, onBeforeUnmount, onMounted } from 'vue'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { FIELD_AUTOFOCUS_EVENT } from '#shared/components/Form/utils.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { waitForAncestorAnimations } from '#shared/utils/animations.ts'

import type { SelectDropdownElements } from './types.ts'

export const useSelectDropdown = (
  context: FormFieldContext<{ autoOpenDropdown?: boolean; noFiltering?: boolean }>,
  { input, output, filterInput, dropdown }: SelectDropdownElements,
) => {
  const { activateTabTrap, deactivateTabTrap } = useTrapTab(input, true)

  const inputElementBounds = useElementBounding(input)
  const windowSize = useWindowSize()

  const isBelowHalfScreen = computed(() => inputElementBounds.y.value > windowSize.height.value / 2)
  const isInputVisible = !!VITE_TEST_MODE || useElementVisibility(input)

  let openRequest = 0

  const cancelPendingOpen = () => {
    openRequest += 1
    if (input.value) delete input.value.dataset.dropdownOpening
  }

  const openSelectDropdown = () => {
    cancelPendingOpen()

    if (dropdown.value?.isOpen || context.disabled) return
    if (!input.value) return

    dropdown.value?.openDropdown(inputElementBounds, windowSize.height)

    requestAnimationFrame(() => {
      activateTabTrap()
      if (context.noFiltering) output.value?.focus()
      else filterInput.value?.focus()
    })
  }

  const openOrMoveFocusToDropdown = (lastOption = false) => {
    if (!dropdown.value?.isOpen) {
      openSelectDropdown()
      return
    }

    deactivateTabTrap()

    nextTick(() => {
      requestAnimationFrame(() => {
        dropdown.value?.moveFocusToDropdown(lastOption)
      })
    })
  }

  const hasFocus = () => !!input.value?.contains(document.activeElement)

  const openSelectDropdownWhenSettled = async () => {
    // The dropdown is positioned from the field's bounds, which a transform (e.g. a flyout sliding
    //   in) changes without any resize or scroll event to update them. A `<Transition>` starts its
    //   animation only a frame or two after mounting, so a few idle frames are awaited as well.
    // The user may focus another field or toggle the dropdown meanwhile, which drops the open.
    //   System specs wait for the data attribute to go before they click the field.
    if (!input.value) return

    const focusedElement = document.activeElement
    const request = ++openRequest

    input.value.dataset.dropdownOpening = 'true'
    await waitForAncestorAnimations(input.value)

    if (request !== openRequest) return
    if (document.activeElement !== focusedElement && !hasFocus()) {
      cancelPendingOpen()
      return
    }

    inputElementBounds.update()
    openSelectDropdown()
  }

  // Opened only on autofocus, so tabbing through a form does not pop up every dropdown.
  //   A field with a value stays closed, as an open dropdown hides the value behind its filter.
  const autofocusReceipt = context.node.on(FIELD_AUTOFOCUS_EVENT, () => {
    if (context.fns.hasValue(context._value)) return

    openSelectDropdownWhenSettled()
  })

  onMounted(async () => {
    if (!context.autoOpenDropdown) return

    // Opening during the mount races with the parent's focus and click-outside wiring.
    await nextTick()
    openSelectDropdownWhenSettled()
  })

  onBeforeUnmount(() => {
    context.node.off(autofocusReceipt)
  })

  return {
    activateTabTrap,
    deactivateTabTrap,
    isBelowHalfScreen,
    isInputVisible,
    openSelectDropdown,
    openOrMoveFocusToDropdown,
  }
}
