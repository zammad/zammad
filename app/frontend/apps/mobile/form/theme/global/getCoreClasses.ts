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
      label: `${classes.textarea?.label || ''} cursor-text`,
      input: `${classes.textarea?.input || ''} min-h-[100px]`,
    }),
    checkbox: {
      wrapper: `${
        classes.checkbox?.wrapper || ''
      } flex-row-reverse w-full justify-between h-14 ltr:pl-2 rtl:pr-2`,
    },
    tags: addBlockFloatingLabel({
      ...(classes.tags || {}),
      outer: `${classes.tags?.outer || ''} field-tags min-h-[3.5rem]`,
    }),
    select: addBlockFloatingLabel({
      ...(classes.select || {}),
      outer: `${classes.select?.outer || ''} field-select min-h-[3.5rem]`,
    }),
    treeselect: addBlockFloatingLabel({
      ...(classes.treeselect || {}),
      outer: `${
        classes.treeselect?.outer || ''
      } field-treeselect min-h-[3.5rem]`,
    }),
    autocomplete: addBlockFloatingLabel({
      ...(classes.autocomplete || {}),
      outer: `${
        classes.autocomplete?.outer || ''
      } field-autocomplete min-h-[3.5rem]`,
    }),
    customer: addBlockFloatingLabel({
      ...(classes.customer || {}),
      outer: `${classes.customer?.outer || ''} field-customer min-h-[3.5rem]`,
    }),
    organization: addBlockFloatingLabel({
      ...(classes.organization || {}),
      outer: `${
        classes.organization?.outer || ''
      } field-organization min-h-[3.5rem]`,
    }),
    recipient: addBlockFloatingLabel({
      ...(classes.recipient || {}),
      outer: `${
        classes.recipient?.outer || ''
      } field-autocomplete min-h-[3.5rem]`,
    }),
    button: addButtonVariants(classes.button),
    submit: addButtonVariants(classes.submit),
  }
}

export default getCoreClasses
