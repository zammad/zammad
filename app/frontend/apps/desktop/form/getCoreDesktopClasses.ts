// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { extendClasses } from '#shared/form/plugins/utils.ts'
import type { FormThemeExtension } from '#shared/types/form.ts'

const textInputClasses = () => {
  return {
    input: 'bg-base-300 py-2 px-3 rounded-lg text-base w-full h-10',
    label: 'text-base px-2',
    inner: 'relative',
  }
}

export const getCoreDesktopClasses: FormThemeExtension = (classes) => {
  return {
    global: {
      label: 'formkit-required:required formkit-invalid:text-red-bright',
      messages: 'px-2 pt-1',
      help: 'px-2 pb-2',
    },
    text: textInputClasses(),
    password: textInputClasses(),
    checkbox: extendClasses(classes.checkbox, {
      wrapper: 'ltr:pl-2 rtl:pr-2 w-full select-none',
      decorator: 'text-white',
      input:
        'h-4 w-4 border-[1.5px] text-white border-base-300 rounded-sm bg-transparent checked:bg-primary checked:border-primary',
    }),
  }
}
