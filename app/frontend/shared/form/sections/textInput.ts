// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createSection } from '@formkit/inputs'

// FormKit's stock text input renders a disabled field with the `disabled`
//   attribute, which natively blocks scrolling and text selection, so overflowing
//   content would be unreachable (#6494). A readonly input without tab stop keeps
//   the content readable, `aria-disabled` keeps the state exposed to assistive
//   technology, and `$disabled` still drives value handling and all
//   `formkit-disabled:` styling.
export const textInput = createSection('input', () => ({
  $el: 'input',
  bind: '$attrs',
  attrs: {
    type: '$type',
    readonly: { if: '$disabled', then: true, else: '$attrs.readonly' },
    'aria-disabled': '$disabled || undefined',
    tabindex: { if: '$disabled', then: '-1', else: '$attrs.tabindex' },
    name: '$node.name',
    onInput: '$handlers.DOMInput',
    onBlur: '$handlers.blur',
    value: '$_value',
    id: '$id',
    'aria-describedby': '$describedBy',
    'aria-required': '$state.required || undefined',
  },
}))
