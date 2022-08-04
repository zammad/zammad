// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses } from '@shared/types/form'

const defaultTextInput: Record<string, string> = {
  input: 'block focus:outline-none focus:ring-0',
}

const classes: FormThemeClasses = {
  global: {
    outer: 'formkit-disabled:opacity-30',
    help: 'mt-0.5 text-xs',
    messages: 'list-none p-0 mt-1 mb-0',
    message: 'text-red mb-1 text-xs',
  },
  text: defaultTextInput,
  email: defaultTextInput,
  number: defaultTextInput,
  search: defaultTextInput,
  tel: defaultTextInput,
  time: defaultTextInput,
  date: defaultTextInput,
  datetime: defaultTextInput,
  textarea: defaultTextInput,
  password: defaultTextInput,
  checkbox: {
    wrapper: 'inline-flex items-center cursor-pointer',
    inner: 'mr-2',
    input:
      'appearance-none focus:outline-none focus:ring-0 focus:ring-offset-0',
  },
  radio: {
    wrapper: 'inline-flex items-center cursor-pointer',
    inner: 'mr-2',
    input:
      'appearance-none focus:outline-none focus:ring-0 focus:ring-offset-0',
  },
}

export default classes
