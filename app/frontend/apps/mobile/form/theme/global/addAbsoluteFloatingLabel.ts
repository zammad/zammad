// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from './utils'
import { clean } from './utils'

/**
 * Creates classes for a floating input label. Here we don't have a problem, where
 * we might need to display several rows of information on the screen, so we can use "absolute".
 */
export const addAbsoluteFloatingLabel = (classes: Classes = {}) => {
  const {
    input = '',
    label = '',
    outer = '',
    wrapper = '',
    arrow = '',
  } = classes

  return {
    outer: clean(
      `${outer}
      absolute-floating-input
      relative flex-col flex px-2
      formkit-invalid:bg-red-dark
      formkit-errors:bg-red-dark
    `,
    ),
    wrapper: `${wrapper} relative flex-1`,
    inner: 'flex ltr:pr-2 rtl:pl-2',
    block: 'flex',
    input: clean(`
        ${input}
        w-full
        h-14
        text-sm
        bg-transparent
        border-none
        focus:outline-none
        placeholder:text-transparent
        focus-within:pt-8
        formkit-populated:pt-8
      `),
    label: clean(`
        ${label}
        absolute top-0 ltr:left-0 rtl:right-0
        py-4 px-2 h-14
        text-base
        transition-all duration-100 ease-in-out origin-left
        pointer-events-none
        formkit-populated:-translate-y-3 formkit-populated:translate-x-6
        formkit-populated:scale-75 formkit-populated:opacity-75
        formkit-required:required
        formkit-invalid:text-red-bright
      `),
    arrow: `${arrow} formkit-arrow flex items-center`,
    messages: 'px-2',
  }
}
