// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses } from '@common/types/form'

const defaultTextInput: Record<string, string> = {
  input: 'block',
}

const classes: FormThemeClasses = {
  global: {
    outer: 'mb-2 formkit-disabled:opacity-30',
    help: 'mt-0.5 text-xs',
    messages: 'list-none p-0 mt-1 mb-0',
    message: 'text-red mb-1 text-xs',
    input: 'formkit-invalid:border-red formkit-invalid:border-solid',
  },
  text: defaultTextInput,
  email: defaultTextInput,
  number: defaultTextInput,
  search: defaultTextInput,
  tel: defaultTextInput,
  time: defaultTextInput,
  date: defaultTextInput,
  'datetime-local': defaultTextInput,
  textarea: defaultTextInput,
  password: defaultTextInput,
}

export default classes
