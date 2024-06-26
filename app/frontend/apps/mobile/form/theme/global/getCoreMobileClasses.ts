// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { clean, extendClasses } from '#shared/form/plugins/utils.ts'
import type { Classes } from '#shared/form/plugins/utils.ts'
import type {
  FormThemeClasses,
  FormThemeExtension,
} from '#shared/types/form.ts'

import { addAbsoluteFloatingLabel } from './addAbsoluteFloatingLabel.ts'
import { addBlockFloatingLabel } from './addBlockFloatingLabel.ts'
import { addFloatingTextareaLabel } from './addFloatingTextareaLabel.ts'
import { addStaticFloatingLabel } from './addStaticFloatingLabel.ts'

export const addButtonVariants = (classes: Classes = {}): Classes => {
  return extendClasses(classes, {
    wrapper: 'relative',
    input:
      'formkit-variant-primary:bg-blue formkit-variant-submit:text-black formkit-variant-submit:bg-yellow formkit-variant-submit:font-semibold formkit-variant-danger:bg-red-dark formkit-variant-danger:text-red-bright bg-transparent text-white',
  })
}

const getCoreClasses: FormThemeExtension = (classes: FormThemeClasses) => {
  return {
    global: extendClasses(classes.global, {
      outer: 'formkit-invalid:bg-red-dark formkit-errors:bg-red-dark',
      label: 'formkit-required:required formkit-invalid:text-red-bright',
      messages: 'px-2',
      message: 'text-red-bright pb-1',
      help: 'mt-0.5 px-2 pb-2',
      arrow: 'formkit-arrow formkit-disabled:opacity-30 flex items-center',
      prefixIcon:
        'absolute top-1/2 -translate-y-1/2 transform ltr:left-3 rtl:right-3',
      suffixIcon:
        'absolute top-1/2 flex -translate-y-1/2 transform items-center justify-center fill-current text-white ltr:right-3 rtl:left-3',
    }),
    text: addAbsoluteFloatingLabel(classes.text),
    email: addAbsoluteFloatingLabel(classes.email),
    url: addAbsoluteFloatingLabel(classes.url),
    number: addAbsoluteFloatingLabel(classes.number),
    search: extendClasses(classes.search, {
      inner: 'flex',
      wrapper: 'px-3',
    }),
    tel: addAbsoluteFloatingLabel(classes.tel),
    time: addAbsoluteFloatingLabel(classes.time),
    password: addAbsoluteFloatingLabel(classes.password),
    date: addAbsoluteFloatingLabel(classes.date),
    datetime: addAbsoluteFloatingLabel(classes.datetime),
    editor: addFloatingTextareaLabel(
      extendClasses(classes.editor, {
        input: 'min-h-[80px]',
      }),
    ),
    textarea: addFloatingTextareaLabel(
      extendClasses(classes.textarea, {
        input: 'min-h-[100px]',
      }),
    ),
    checkbox: extendClasses(classes.checkbox, {
      wrapper: 'w-full select-none ltr:pl-2 rtl:pr-2',
      inner: 'ltr:mr-2 rtl:ml-2',
      input:
        'focus:border-blue focus:bg-blue-highlight checked:focus:color-blue checked:bg-blue checked:border-blue checked:focus:bg-blue checked:hover:bg-blue h-4 w-4 rounded-sm border-[1.5px] border-white bg-transparent',
    }),
    radio: extendClasses(classes.radio, {
      inner: 'ltr:mr-2 rtl:ml-2',
    }),
    toggle: extendClasses(classes.toggle, {
      outer: 'relative px-2',
      wrapper: 'inline-flex h-14 w-full px-2',
      label: 'flex h-full w-full cursor-pointer items-center text-base',
      inner: 'flex h-full items-center',
    }),
    tags: addBlockFloatingLabel(classes.tags),
    select: addBlockFloatingLabel(classes.select),
    treeselect: addBlockFloatingLabel(classes.treeselect),
    autocomplete: addBlockFloatingLabel(classes.autocomplete),
    customer: addBlockFloatingLabel(classes.customer),
    organization: addBlockFloatingLabel(classes.organization),
    externalDataSource: addBlockFloatingLabel(classes.externalDataSource),
    recipient: addBlockFloatingLabel(classes.recipient),
    button: addButtonVariants(classes.button),
    submit: addButtonVariants(classes.submit),
    security: addStaticFloatingLabel(
      extendClasses(classes.security, {
        label: clean(`scale-80 -translate-y-[0.4rem] text-xs`),
      }),
    ),
    file: {
      messages: 'px-4',
    },
  }
}

export default getCoreClasses
