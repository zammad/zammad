// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses, FormThemeExtension } from '@shared/types/form'

type Classes = Record<string, string>

export const addFloatingLabel = (classes: Classes = {}): Classes => {
  const inputClass = classes.input || ''
  const labelClass = classes.label || ''

  return {
    outer: `${classes.outer || ''} floating-input`,
    wrapper: `${classes.wrapper || ''} formkit-invalid:bg-red/10 relative px-3`,
    inner: 'flex',
    input: `
      ${inputClass}
      w-full
      px-0
      h-14
      text-sm
      bg-transparent
      border-none
      focus:outline-none
      placeholder:text-transparent
      focus-within:pt-8
      formkit-populated:pt-8
    `,
    label: `
      ${labelClass}
      absolute top-0 ltr:left-0 rtl:right-0
      py-5 px-3 h-14
      text-base
      transition-all duration-100 ease-in-out origin-left
      pointer-events-none
      formkit-populated:-translate-y-3 formkit-populated:translate-x-6
      formkit-populated:scale-75 formkit-populated:opacity-75
      formkit-required:required
      formkit-invalid:text-red
    `,
  }
}

export const addDateLabel = (classes: Classes = {}): Classes => {
  const newClasses = addFloatingLabel(classes)
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
    } formkit-variant-primary:bg-blue formkit-variant-secondary:bg-transparent`,
  }
}

const getCoreClasses: FormThemeExtension = (classes: FormThemeClasses) => {
  return {
    global: {},
    text: addFloatingLabel(classes.text),
    email: addFloatingLabel(classes.email),
    number: addFloatingLabel(classes.number),
    search: addFloatingLabel(classes.search),
    tel: addFloatingLabel(classes.tel),
    time: addFloatingLabel(classes.time),
    date: addDateLabel(classes.date),
    datetime: addDateLabel(classes.datetime),
    textarea: addFloatingLabel(classes.textarea),
    password: addFloatingLabel(classes.password),
    select: addFloatingLabel({
      ...(classes.select || {}),
      outer: `${classes.select && classes.select.outer} field-select`,
    }),
    treeselect: addFloatingLabel({
      ...(classes.select || {}),
      outer: `${classes.select && classes.select.outer} field-treeselect`,
    }),
    button: addButtonVariants(classes.button),
    submit: addButtonVariants(classes.submit),
  }
}

export default getCoreClasses
