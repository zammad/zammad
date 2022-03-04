// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FormFieldType } from '@common/types/form'
import {
  button as buttonDefinition,
  submit as submitDefinition,
} from '@formkit/inputs'

// TODO: Build-In loading cycle funcitonality for the buttons?
// TODO: Build-In Variants? => Best solution with Tailwind?

const buttonInputs: FormFieldType[] = [
  {
    fieldType: 'button',
    definition: buttonDefinition,
  },
  {
    fieldType: 'submit',
    definition: submitDefinition,
  },
]

export default buttonInputs
