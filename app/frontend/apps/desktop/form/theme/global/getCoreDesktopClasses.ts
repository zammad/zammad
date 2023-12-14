// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { extendClasses } from '#shared/form/plugins/utils.ts'
import type { Classes } from '#shared/form/plugins/utils.ts'
import type {
  FormThemeClasses,
  FormThemeExtension,
} from '#shared/types/form.ts'

const textInputClasses = (classes: Classes = {}) => {
  return extendClasses(classes, {
    wrapper: 'flex flex-col items-start justify-start mb-1.5 last:mb-0',
    input: 'grow bg-transparent',
    label: 'block mb-1 text-sm text-gray-100 dark:text-neutral-400',
    inner: `flex items-center w-full h-10 py-2 px-2.5 bg-blue-200 dark:bg-gray-700 text-black dark:text-white hover:outline hover:outline-2 hover:outline-offset-2 hover:outline-blue-600 dark:hover:outline-blue-900 focus-within:outline focus-within:outline-2 focus-within:outline-offset-2 focus-within:outline-blue-800 hover:focus-within:outline-blue-800 dark:hover:focus-within:outline-blue-800 formkit-invalid:outline formkit-invalid:outline-2 formkit-invalid:outline-offset-2 formkit-invalid:outline-red-500`,
  })
}

export const getCoreDesktopClasses: FormThemeExtension = (
  classes: FormThemeClasses,
) => {
  return {
    global: extendClasses(classes.global, {
      wrapper: 'flex-grow',
      block: 'flex items-end',
      label: 'formkit-required:required formkit-invalid:text-red-500',
      inner: 'rounded-lg text-sm',
      messages: 'mt-1 formkit-invalid:text-red-500',
      help: 'text-stone-200 dark:text-neutral-500 mt-1',
      prefixIcon:
        'relative h-5 w-5 flex justify-center items-center fill-current text-stone-200 dark:text-neutral-500',
      suffixIcon:
        'relative h-5 w-5 flex justify-center items-center fill-current text-stone-200 dark:text-neutral-500',
    }),
    text: textInputClasses(classes.text),
    password: textInputClasses(classes.password),
    email: textInputClasses(classes.email),
    url: textInputClasses(classes.url),
    number: textInputClasses(classes.number),
    tel: textInputClasses(classes.tel),
    time: textInputClasses(classes.time),
    search: textInputClasses(classes.search),
    checkbox: {
      outer: 'leading-none',
      wrapper: 'inline-flex items-center cursor-pointer select-none',
      label: 'text-sm text-gray-100 dark:text-neutral-400',
      inner: 'w-5 h-5 flex justify-center items-center ltr:mr-1 rtl:ml-1',
      input:
        'peer appearance-none focus:outline-none focus:ring-0 focus:ring-offset-0',
      decorator:
        'w-3 h-3 relative border border-stone-200 dark:border-neutral-500 peer-hover:border-blue-600 dark:peer-hover:border-blue-900 peer-focus:border-blue-800 rounded-sm bg-transparent text-stone-200 dark:text-neutral-500 peer-hover:text-blue-600 dark:peer-hover:text-blue-900 peer-focus:text-blue-800',
      decoratorIcon:
        'absolute invisible formkit-is-checked:visible -top-px ltr:-left-px rtl:-right-px',
    },
    radio: extendClasses(classes.radio, {
      inner: 'ltr:mr-1 rtl:ml-1',
    }),
  }
}
