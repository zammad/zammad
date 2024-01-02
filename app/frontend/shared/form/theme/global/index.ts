// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses } from '#shared/types/form.ts'

const defaultTextInput: Record<string, string> = {
  input: 'block focus:outline-none focus:ring-0',
}

const classes: FormThemeClasses = {
  global: {
    wrapper: 'formkit-disabled:opacity-30',
    label: 'formkit-label-hidden:sr-only',
    help: 'text-xs',
    messages: 'list-none',
    message: 'text-xs',
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
    inner: 'flex',
    input:
      'appearance-none focus:outline-none focus:ring-0 focus:ring-offset-0',
    decorator:
      'relative invisible formkit-is-checked:visible rtl:-right-4 ltr:-left-4',
    decoratorIcon: 'absolute',
  },
  radio: {
    wrapper: 'inline-flex items-center cursor-pointer',
    inner: 'flex',
    input:
      'appearance-none focus:outline-none focus:ring-0 focus:ring-offset-0',
    decorator:
      'relative invisible formkit-is-checked:visible rtl:-right-4 ltr:-left-4',
    decoratorIcon: 'absolute',
  },
  button: {
    input: 'flex justify-center items-center',
  },
  submit: {
    input: 'flex justify-center items-center',
  },
}

export default classes
