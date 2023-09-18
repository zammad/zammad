// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from './utils.ts'
import { clean, extendClasses } from './utils.ts'

/**
 * Creates classes for a floating input label. Here we don't have a problem, where
 * we might need to display several rows of information on the screen, so we can use "absolute".
 */
export const addAbsoluteFloatingLabel = (classes: Classes = {}) => {
  return extendClasses(classes, {
    outer: clean(`
      absolute-floating-input
      relative flex-col flex px-2
    `),
    wrapper: 'relative flex-1',
    inner: 'flex ltr:pr-2 rtl:pl-2',
    block: 'flex',
    // text-base ensures there is no zoom when you click on the input on iOS
    input: clean(`
      w-full
      h-14
      text-base
      bg-transparent
      border-none
      focus:outline-none
      placeholder:text-transparent
      focus-within:pt-8
      formkit-populated:pt-8
      formkit-label-hidden:pt-2
    `),
    label: clean(`
      absolute top-0 ltr:left-0 rtl:right-0
      py-4 px-2 h-14
      text-base
      transition-all duration-100 ease-in-out origin-left
      pointer-events-none
    `),
  })
}
