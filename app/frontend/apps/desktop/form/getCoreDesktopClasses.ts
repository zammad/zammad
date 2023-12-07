// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { extendClasses } from '#shared/form/plugins/utils.ts'
import type { FormThemeExtension } from '#shared/types/form.ts'

const textInputClasses = () => {
  return {
    input:
      'bg-blue-200 dark:bg-gray-700 formkit-invalid:bg-pink-100 dark:formkit-invalid:bg-red-900 py-2 px-2.5 rounded-lg text-sm w-full',
    label: 'text-sm text-gray-100 dark:text-neutral-400',
    inner: 'relative',
  }
}

export const getCoreDesktopClasses: FormThemeExtension = (classes) => {
  return {
    global: {
      label: 'formkit-required:required formkit-invalid:text-red-500',
      messages: 'pt-1 formkit-invalid:text-red-500',
      help: 'pb-2',
      suffixIcon:
        'absolute top-1/2 transform -translate-y-1/2 rtl:left-3 ltr:right-3 fill-current flex justify-center items-center text-stone-200 dark:text-neutral-500',
    },
    text: textInputClasses(),
    password: textInputClasses(),
    checkbox: extendClasses(classes.checkbox, {
      wrapper: 'p-1 select-none',
      label: 'text-sm text-gray-100 dark:text-neutral-400',
      inner: 'ltr:mr-1 rtl:ml-1',
      input:
        'h-4 w-4 border-[1.5px] text-white border-stone-200 dark:border-neutral-500 rounded-sm bg-transparent checked:border-stone-200 dark:checked:border-neutral-500',
      decorator: 'text-stone-200 dark:text-neutral-500',
    }),
    radio: extendClasses(classes.radio, {
      inner: 'ltr:mr-1 rtl:ml-1',
    }),
  }
}
