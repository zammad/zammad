// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses, FormThemeExtension } from '@shared/types/form'

type Classes = Record<string, string>

export const addFloatingLabel = (classes: Classes): Classes => {
  const inputClass = classes.input || ''
  const labelClass = classes.label || ''
  return {
    outer: `${classes.outer || ''} floating-input`,
    wrapper: `${classes.wrapper || ''} relative`,
    input: `${inputClass} w-full h-14 text-sm bg-gray-500 rounded-xl border-none focus:outline-none placeholder:text-transparent focus-within:pt-8 formkit-populated:pt-8`,
    label: `${labelClass} absolute top-0 left-0 py-5 px-3 h-14 text-base transition-all duration-100 ease-in-out origin-left pointer-events-none formkit-populated:-translate-y-3 formkit-populated:translate-x-1 formkit-populated:scale-75 formkit-populated:opacity-75`,
  }
}

export const addDateLabel = (classes: Classes): Classes => {
  const newClasses = addFloatingLabel(classes)
  return {
    ...newClasses,
    inner: 'flex flex-col items-center bg-gray-500 rounded-xl',
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
  }
}

export default getCoreClasses
