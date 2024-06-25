// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'

import type { FormKitOptionsItem } from '@formkit/inputs'

export interface ToggleButtonsOption extends FormKitOptionsItem<string> {
  icon?: string
}

export type FieldToggleButtonsContext = {
  options: ToggleButtonsOption
}

export interface FieldToggleButtonsProps {
  context: FormFieldContext<FieldToggleButtonsContext>
}
