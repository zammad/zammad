// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses } from '@shared/types/form'

const defaultTextInput: Record<string, string> = {
  input: 'block focus:outline-none focus:ring-0',
}

const classes: FormThemeClasses = {
  global: {
    wrapper: 'formkit-disabled:opacity-30',
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
  toggle: {
    wrapper:
      'inline-flex items-center cursor-pointer flex-row-reverse h-14 px-2',
    inner:
      'mr-2 bg-gray-300 relative inline-flex flex-shrink-0 h-6 w-10 border border-transparent rounded-full cursor-pointer transition-colors ease-in-out duration-200 focus:outline-none focus-within:ring-1 focus-within:ring-white focus-within:ring-opacity-75 formkit-is-checked:bg-blue formkit-invalid:border-red formkit-invalid:border-solid',
    decorator:
      'translate-x-0 pointer-events-none inline-block h-[22px] w-[22px] rounded-full bg-white shadow-lg transform ring-0 transition ease-in-out duration-200 peer-checked:translate-x-4',
    outer: 'px-2',
    input: '$reset peer sr-only',
  },
  radio: {
    wrapper: 'inline-flex items-center cursor-pointer',
    inner: 'mr-2',
    input:
      'appearance-none focus:outline-none focus:ring-0 focus:ring-offset-0',
  },
}

export default classes
