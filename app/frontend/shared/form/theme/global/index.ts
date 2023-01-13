// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses } from '@shared/types/form'

const defaultTextInput: Record<string, string> = {
  input: 'block focus:outline-none focus:ring-0',
}

const classes: FormThemeClasses = {
  global: {
    wrapper: 'formkit-disabled:opacity-30',
    label: 'formkit-label-hidden:sr-only',
    help: 'mt-0.5 text-xs',
    messages: 'list-none',
    message: 'text-red-bright pb-1 text-xs',
  },
  text: defaultTextInput,
  email: defaultTextInput,
  url: defaultTextInput,
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
    input:
      'appearance-none focus:outline-none focus:ring-0 focus:ring-offset-0',
  },
}

export default classes
