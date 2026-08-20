// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { MatchedSelectOption, SelectOption } from '#shared/components/CommonSelect/types.ts'
import type { AutoCompleteOption } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'

import type { UseElementBoundingReturn } from '@vueuse/core'
import type { ConcreteComponent, Ref } from 'vue'

export interface CommonSelectInstance {
  openDropdown(bounds: UseElementBoundingReturn, height: Ref<number>): void
  closeDropdown(): void
  getFocusableOptions(): HTMLElement[]
  moveFocusToDropdown(lastOption: boolean): void
  isOpen: boolean
}

export interface CommonSelectInternalInstance extends Omit<CommonSelectInstance, 'isOpen'> {
  isOpen: Ref<boolean>
}

/**
 * Contract of a `CommonSelect` option component, implemented by `CommonSelectItem` and by any
 *   component passed as the `optionComponent` prop.
 *
 * A custom implementation is responsible for the option semantics itself: the rendered element
 *   must carry `role="option"`, `tabindex="0"` and `aria-selected`, since focus management and
 *   keyboard traversal of the dropdown rely on them. It should also declare all props it does
 *   not use, otherwise they end up as stray attributes on its root element.
 */
export interface CommonSelectOptionProps {
  option: AutoCompleteOption | MatchedSelectOption | SelectOption
  selected?: boolean
  multiple?: boolean
  noLabelTranslate?: boolean
  filter?: string
  optionIconComponent?: ConcreteComponent
  /** Only used for the internal empty state, never passed to a custom option component. */
  noSelectionIndicator?: boolean
  /** Only used for the internal empty state, never passed to a custom option component. */
  noInteraction?: boolean
}

export interface CommonSelectOptionEmits {
  select: [option: SelectOption]
  next: [{ option: AutoCompleteOption; noFocus?: boolean }]
}

export interface DropdownOptionsAction {
  key: string
  label: string
  icon?: string
  onClick: (focus: boolean) => void
}
