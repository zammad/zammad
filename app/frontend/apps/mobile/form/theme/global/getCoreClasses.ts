// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type {
  FormThemeClasses,
  FormThemeExtension,
} from '#shared/types/form.ts'
import { addAbsoluteFloatingLabel } from './addAbsoluteFloatingLabel.ts'
import { addFloatingTextareaLabel } from './addFloatingTextareaLabel.ts'
import { addBlockFloatingLabel } from './addBlockFloatingLabel.ts'
import type { Classes } from './utils.ts'
import { extendClasses } from './utils.ts'
import { addStaticFloatingLabel } from './addStaticFloatingLabel.ts'

export const addDateLabel = (classes: Classes = {}): Classes => {
  const newClasses = addAbsoluteFloatingLabel(classes)
  return {
    ...newClasses,
    inner: 'flex flex-col items-center',
  }
}

export const addButtonVariants = (classes: Classes = {}): Classes => {
  return {
    wrapper: `${classes.wrapper || ''} relative`,
    input: `${
      classes.input || ''
    } bg-transparent text-white formkit-variant-primary:bg-blue formkit-variant-submit:text-black formkit-variant-submit:bg-yellow formkit-variant-submit:font-semibold formkit-variant-danger:bg-red-dark formkit-variant-danger:text-red-bright`,
  }
}

const getCoreClasses: FormThemeExtension = (classes: FormThemeClasses) => {
  return {
    global: {},
    text: addAbsoluteFloatingLabel(classes.text),
    email: addAbsoluteFloatingLabel(classes.email),
    url: addAbsoluteFloatingLabel(classes.url),
    number: addAbsoluteFloatingLabel(classes.number),
    search: { ...classes.search, inner: 'flex', wrapper: 'px-3' },
    tel: addAbsoluteFloatingLabel(classes.tel),
    time: addAbsoluteFloatingLabel(classes.time),
    password: addAbsoluteFloatingLabel(classes.password),
    date: addDateLabel(classes.date),
    datetime: addDateLabel(classes.datetime),
    editor: addFloatingTextareaLabel(classes.editor),
    textarea: addFloatingTextareaLabel(classes.textarea),
    checkbox: extendClasses(classes.checkbox, {
      outer: 'formkit-invalid:bg-red-dark formkit-errors:bg-red-dark',
      wrapper: 'ltr:pl-2 rtl:pr-2 w-full select-none',
      label: 'formkit-required:required',
      help: 'px-2 pb-2',
      input:
        'h-4 w-4 border-[1.5px] border-white rounded-sm bg-transparent focus:border-blue focus:bg-blue-highlight checked:focus:color-blue checked:bg-blue checked:border-blue checked:focus:bg-blue checked:hover:bg-blue',
    }),
    toggle: extendClasses(classes.toggle, {
      outer:
        'relative px-2 formkit-invalid:bg-red-dark formkit-errors:bg-red-dark',
      wrapper: 'inline-flex w-full h-14 px-2',
      label:
        'flex items-center w-full h-full text-base cursor-pointer formkit-required:required',
      help: 'px-2 pb-2',
      inner: 'flex items-center h-full',
    }),
    tags: addBlockFloatingLabel(classes.tags),
    select: addBlockFloatingLabel(classes.select),
    treeselect: addBlockFloatingLabel(classes.treeselect),
    autocomplete: addBlockFloatingLabel(classes.autocomplete),
    customer: addBlockFloatingLabel(classes.customer),
    organization: addBlockFloatingLabel(classes.organization),
    recipient: addBlockFloatingLabel(classes.recipient),
    button: addButtonVariants(classes.button),
    submit: addButtonVariants(classes.submit),
    security: addStaticFloatingLabel(classes.security),
  }
}

export default getCoreClasses
