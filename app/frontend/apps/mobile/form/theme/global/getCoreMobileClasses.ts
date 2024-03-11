// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormThemeClasses,
  FormThemeExtension,
} from '#shared/types/form.ts'
import type { Classes } from '#shared/form/plugins/utils.ts'
import { clean, extendClasses } from '#shared/form/plugins/utils.ts'
import { addAbsoluteFloatingLabel } from './addAbsoluteFloatingLabel.ts'
import { addFloatingTextareaLabel } from './addFloatingTextareaLabel.ts'
import { addBlockFloatingLabel } from './addBlockFloatingLabel.ts'
import { addStaticFloatingLabel } from './addStaticFloatingLabel.ts'

export const addDateLabel = (classes: Classes = {}): Classes => {
  const newClasses = addAbsoluteFloatingLabel(classes)
  // remove padding since we implement it differently for the calendar
  const inner = newClasses.inner.replace(' ltr:pr-2 rtl:pl-2', '')
  return {
    ...newClasses,
    inner: `${inner} flex-col items-center`,
  }
}

export const addButtonVariants = (classes: Classes = {}): Classes => {
  return extendClasses(classes, {
    wrapper: 'relative',
    input:
      'bg-transparent text-white formkit-variant-primary:bg-blue formkit-variant-submit:text-black formkit-variant-submit:bg-yellow formkit-variant-submit:font-semibold formkit-variant-danger:bg-red-dark formkit-variant-danger:text-red-bright',
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
      arrow: 'formkit-arrow flex items-center formkit-disabled:opacity-30',
      prefixIcon:
        'absolute top-1/2 transform -translate-y-1/2 rtl:right-3 ltr:left-3',
      suffixIcon:
        'absolute top-1/2 transform -translate-y-1/2 rtl:left-3 ltr:right-3 text-white fill-current flex justify-center items-center',
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
    date: addDateLabel(classes.date),
    datetime: addDateLabel(classes.datetime),
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
      wrapper: 'ltr:pl-2 rtl:pr-2 w-full select-none',
      inner: 'ltr:mr-2 rtl:ml-2',
      input:
        'h-4 w-4 border-[1.5px] border-white rounded-sm bg-transparent focus:border-blue focus:bg-blue-highlight checked:focus:color-blue checked:bg-blue checked:border-blue checked:focus:bg-blue checked:hover:bg-blue',
    }),
    radio: extendClasses(classes.radio, {
      inner: 'ltr:mr-2 rtl:ml-2',
    }),
    toggle: extendClasses(classes.toggle, {
      outer: 'relative px-2',
      wrapper: 'inline-flex w-full h-14 px-2',
      label: 'flex items-center w-full h-full text-base cursor-pointer',
      inner: 'flex items-center h-full',
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
        label: clean(`
          -translate-y-[0.4rem]
          scale-80
          text-xs
        `),
      }),
    ),
    file: {
      messages: 'px-4',
    },
  }
}

export default getCoreClasses
