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

export const addSelectLabel = (classes: Classes = {}): Classes => {
  const {
    label = '',
    arrow = '',
    outer = '',
    wrapper = '',
    inner = '',
  } = classes

  return addBlockFloatingLabel({
    ...classes,
    label: `${label} formkit-label-hidden:hidden`,
    arrow: `${arrow} formkit-label-hidden:hidden`,
    outer: `${outer} formkit-label-hidden:!min-h-[initial] formkit-label-hidden:!p-0`,
    wrapper: `${wrapper} formkit-label-hidden:!py-0`,
    inner: `${inner} formkit-label-hidden:!p-0`,
  })
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
      outer: 'formkit-invalid:bg-red/10',
      wrapper: `${classes.checkbox?.wrapper || ''} w-full justify-between`,
      label: `${classes.checkbox?.label || ''} formkit-required:required`,
    },
    toggle: {
      wrapper: `${classes.toggle?.wrapper || ''} w-full justify-between`,
      label: `${classes.toggle?.label || ''} formkit-required:required`,
    },
    tags: addBlockFloatingLabel(classes.tags),
    select: addSelectLabel(classes.select),
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
