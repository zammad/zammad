// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { extendClasses } from '#shared/form/plugins/utils.ts'
import type { Classes } from '#shared/form/plugins/utils.ts'
import type {
  FormThemeClasses,
  FormThemeExtension,
} from '#shared/types/form.ts'

const textInputClasses = (classes: Classes = {}) => {
  const innerInvalidClasses =
    'formkit-invalid:outline formkit-invalid:outline-1 formkit-invalid:outline-offset-1 formkit-invalid:outline-red-500 dark:hover:formkit-invalid:outline-red-500'
  const innerErrorsClasses = innerInvalidClasses.replace(/invalid/g, 'errors')

  return extendClasses(classes, {
    wrapper: 'flex flex-col items-start justify-start',
    input:
      'grow bg-transparent px-2.5 py-2 placeholder:text-stone-200 read-only:text-stone-200 dark:placeholder:text-neutral-500 dark:read-only:text-neutral-500',
    label: 'mb-1 block text-sm text-gray-100 dark:text-neutral-400',
    inner: `flex h-10 w-full items-center bg-blue-200 text-black focus-within:outline focus-within:outline-1 focus-within:outline-offset-1 focus-within:outline-blue-800 hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 hover:focus-within:outline-blue-800 dark:bg-gray-700 dark:text-white dark:hover:outline-blue-900 dark:hover:focus-within:outline-blue-800 ${innerInvalidClasses} ${innerErrorsClasses}`,
  })
}

const selectInputClasses = (classes: Classes = {}) =>
  extendClasses(classes, {
    inner:
      'formkit-invalid:outline formkit-invalid:outline-1 formkit-invalid:outline-offset-1 formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:outline-1 formkit-errors:outline-offset-1 formkit-errors:outline-red-500 w-full',
  })

export const getCoreDesktopClasses: FormThemeExtension = (
  classes: FormThemeClasses,
) => {
  return {
    global: extendClasses(classes.global, {
      wrapper:
        'formkit-disabled:opacity-50 formkit-disabled:pointer-events-none flex-grow',
      block: 'flex items-end',
      label:
        'formkit-required:required formkit-invalid:text-red-500 formkit-errors:text-red-500 mb-1 block text-sm text-gray-100 dark:text-neutral-400',
      inner: 'rounded-lg text-sm',
      messages: 'formkit-invalid:text-red-500 formkit-errors:text-red-500 mt-1',
      help: 'mt-1 text-stone-200 dark:text-neutral-500',
      prefixIcon:
        'relative flex h-4 w-4 items-center justify-center fill-current text-stone-200 hover:text-black focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 ltr:ml-2.5 rtl:mr-2.5 dark:text-neutral-500 dark:hover:text-white',
      suffixIcon:
        'relative flex h-4 w-4 items-center justify-center fill-current text-stone-200 hover:text-black focus-visible:rounded-xs focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800 ltr:mr-2.5 rtl:ml-2.5 dark:text-neutral-500 dark:hover:text-white',
    }),
    form: extendClasses(classes.form, {
      messages: 'mb-2.5 flex-wrap space-y-2',
    }),
    text: textInputClasses(classes.text),
    textarea: extendClasses(textInputClasses(classes.textarea), {
      inner: 'h-full',
    }),
    password: textInputClasses(classes.password),
    email: textInputClasses(classes.email),
    url: textInputClasses(classes.url),
    number: textInputClasses(classes.number),
    tel: textInputClasses(classes.tel),
    time: textInputClasses(classes.time),
    search: textInputClasses(classes.search),
    date: textInputClasses(classes.date),
    datetime: textInputClasses(classes.datetime),
    checkbox: {
      outer: 'leading-none',
      wrapper: 'inline-flex items-center cursor-pointer select-none',
      label: 'mb-0! text-sm text-gray-100 dark:text-neutral-400',
      inner:
        'w-5 h-5 flex justify-center items-center ltr:mr-1 rtl:ml-1 formkit-label-hidden:m-0',
      input:
        'peer appearance-none focus:outline-hidden focus:ring-0 focus:ring-offset-0',
      decorator:
        'w-3 h-3 relative border peer-hover:border-blue-600 dark:peer-hover:border-blue-900 peer-focus:border-blue-800 peer-focus:outline peer-focus:outline-1 peer-focus:outline-offset-1 peer-focus:outline-blue-800 rounded-xs bg-transparent peer-hover:text-blue-600 dark:peer-hover:text-blue-900 peer-focus:text-blue-800 formkit-checked:peer-hover:border-blue-600 dark:formkit-checked:peer-hover:border-blue-900 formkit-checked:peer-focus:border-blue-800 formkit-checked:peer-focus:outline-blue-800 formkit-checked:peer-hover:text-blue-600 dark:formkit-checked:peer-hover:text-blue-900 formkit-checked:peer-focus:text-blue-800',
      decoratorIcon:
        'absolute invisible formkit-is-checked:visible -top-px ltr:-left-px rtl:-right-px',
    },
    radio: extendClasses(classes.radio, {
      inner: 'ltr:mr-1 rtl:ml-1',
    }),
    imageUpload: extendClasses(classes.imageUpload, {
      inner:
        'formkit-invalid:outline formkit-invalid:outline-1 formkit-invalid:outline-offset-1 formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:outline-1 formkit-errors:outline-offset-1 formkit-errors:outline-red-500 w-full bg-blue-200 dark:bg-gray-700',
    }),
    select: selectInputClasses(classes.select),
    treeselect: selectInputClasses(classes.treeselect),
    autocomplete: selectInputClasses(classes.autocomplete),
    agent: selectInputClasses(classes.agent),
    customer: selectInputClasses(classes.customer),
    recipient: selectInputClasses(classes.recipient),
    ticket: selectInputClasses(classes.ticket),
    toggle: extendClasses(classes.toggle, {
      wrapper: 'flex h-10 flex-row-reverse items-center gap-1.5',
      label: '!mb-0 grow',
      inner: 'leading-[0]',
    }),
    groupPermissions: extendClasses(classes.groupPermissions, {
      inner:
        'formkit-invalid:outline formkit-invalid:outline-1 formkit-invalid:outline-offset-1 formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:outline-1 formkit-errors:outline-offset-1 formkit-errors:outline-red-500 w-full bg-blue-200 dark:bg-gray-700',
    }),
    editor: extendClasses(classes.editor, {
      wrapper: 'max-w-full',
      input: 'min-h-[76px] text-sm text-black outline-hidden dark:text-white',
      inner:
        'bg-blue-200 focus-within:outline focus-within:outline-1 focus-within:outline-offset-1 focus-within:outline-blue-800 hover:outline hover:outline-1 hover:outline-offset-1 hover:outline-blue-600 focus-within:hover:outline-blue-800 focus-visible:outline-1 dark:bg-gray-700 dark:hover:outline-blue-900 dark:focus-within:hover:outline-blue-800',
    }),
    // TODO: check...
    file: extendClasses(classes.file, {
      input: 'p-1',
      inner:
        'formkit-invalid:outline formkit-invalid:outline-1 formkit-invalid:outline-offset-1 formkit-invalid:outline-red-500 formkit-errors:outline formkit-errors:outline-1 formkit-errors:outline-offset-1 formkit-errors:outline-red-500 w-full bg-blue-200 dark:bg-gray-700',
      messages: 'px-4',
    }),
  }
}
