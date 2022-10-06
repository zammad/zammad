// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormThemeClasses, FormThemeExtension } from '@shared/types/form'
import { addAbsoluteFloatingLabel } from './addAbsoluteFloatingLabel'
import { addFloatingTextareaLabel } from './addFloatingTextareaLabel'
import { addBlockFloatingLabel } from './addBlockFloatingLabel'
import type { Classes } from './utils'

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
    } formkit-variant-primary:bg-blue formkit-variant-secondary:bg-transparent`,
  }
}

const getCoreClasses: FormThemeExtension = (classes: FormThemeClasses) => {
  return {
    global: {},
    text: addAbsoluteFloatingLabel(classes.text),
    email: addAbsoluteFloatingLabel(classes.email),
    number: addAbsoluteFloatingLabel(classes.number),
    search: { inner: 'flex', wrapper: 'px-3' },
    tel: addAbsoluteFloatingLabel(classes.tel),
    time: addAbsoluteFloatingLabel(classes.time),
    password: addAbsoluteFloatingLabel(classes.password),
    date: addDateLabel(classes.date),
    datetime: addDateLabel(classes.datetime),
    textarea: addFloatingTextareaLabel({
      ...classes.textarea,
      label: `${classes.textarea?.label} cursor-text`,
      input: `${classes.textarea?.input} min-h-[100px]`,
    }),
    checkbox: {
      wrapper: `${classes.checkbox?.wrapper || ''} w-full justify-between`,
    },
    tags: addBlockFloatingLabel(classes.tags),
    select: addBlockFloatingLabel(classes.select),
    treeselect: addBlockFloatingLabel(classes.treeselect),
    autocomplete: addBlockFloatingLabel(classes.autocomplete),
    customer: addBlockFloatingLabel(classes.customer),
    organization: addBlockFloatingLabel(classes.organization),
    recipient: addBlockFloatingLabel(classes.recipient),
    button: addButtonVariants(classes.button),
    submit: addButtonVariants(classes.submit),
  }
}

export default getCoreClasses
