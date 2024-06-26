// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from '#shared/form/plugins/utils.ts'
import { clean, extendClasses } from '#shared/form/plugins/utils.ts'

/**
 * Creates classes for a floating input label. Here we don't have a problem, where
 * we might need to display several rows of information on the screen, so we can use "absolute".
 */
export const addAbsoluteFloatingLabel = (classes: Classes = {}) => {
  return extendClasses(classes, {
    outer: clean(`absolute-floating-input relative flex flex-col px-2`),
    wrapper: 'relative flex-1',
    inner: 'flex ltr:pr-2 rtl:pl-2',
    block: 'flex',
    // text-base ensures there is no zoom when you click on the input on iOS
    input: clean(
      `formkit-populated:pt-8 formkit-label-hidden:pt-2 h-14 w-full border-none bg-transparent text-base placeholder:text-transparent focus-within:pt-8 focus:outline-none`,
    ),
    label: clean(
      `pointer-events-none absolute top-0 h-14 origin-left px-2 py-4 text-base transition-all duration-100 ease-in-out ltr:left-0 rtl:right-0`,
    ),
  })
}
