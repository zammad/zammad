// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import createInput from '#shared/form/core/createInput.ts'
import addLink from '#shared/form/features/addLink.ts'
import formUpdaterTrigger from '#shared/form/features/formUpdaterTrigger.ts'

import FieldToggleInput from './FieldToggleInput.vue'

import type { FormKitBaseSlots, FormKitInputs } from '@formkit/inputs'

declare module '@formkit/inputs' {
  // oxlint-disable-next-line no-unused-vars
  interface FormKitInputProps<Props extends FormKitInputs<Props>> {
    toggle: {
      type: 'toggle'
      value?: boolean
      variants?: {
        true?: string
        false?: string
      }
      // Optional icon shown inside the knob per state.
      icons?: {
        true?: string
        false?: string
      }
      // Render the current variant label next to the switch.
      inlineLabel?: boolean
      // Invert only the visual on-state (knob side + track) without changing the value, e.g. a
      //  visibility switch whose value is `internal` but whose "on" side should read as public.
      invertVisual?: boolean
      size?: 'medium' | 'small'
    }
  }

  interface FormKitInputSlots<Props extends FormKitInputs<Props>> {
    toggle: FormKitBaseSlots<Props>
  }
}

const fieldDefinition = createInput(
  FieldToggleInput,
  ['variants', 'icons', 'inlineLabel', 'invertVisual', 'size'],
  {
    features: [addLink, formUpdaterTrigger()],
  },
)

export default {
  fieldType: 'toggle',
  definition: fieldDefinition,
}
