// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { CommonSelectInstance } from '#desktop/components/CommonSelect/types.ts'

import type { ShallowRef } from 'vue'

export interface Focusable {
  focus(): void
}

export interface SelectDropdownElements {
  input: Readonly<ShallowRef<HTMLElement | null>>
  output: Readonly<ShallowRef<Focusable | null>>
  filterInput: Readonly<ShallowRef<Focusable | null>>
  dropdown: Readonly<
    ShallowRef<Pick<CommonSelectInstance, 'isOpen' | 'openDropdown' | 'moveFocusToDropdown'> | null>
  >
}
