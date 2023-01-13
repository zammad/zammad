// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from './utils'
import { clean } from './utils'

/**
 * We cannot use absolute positioning for the floating label, because we might need to display
 * several rows of information on the screen - so content can depend on the actual label size and not
 * overlap.
 */
export const addBlockFloatingLabel = (classes: Classes = {}): Classes => {
  const {
    input = '',
    label = '',
    outer = '',
    wrapper = '',
    arrow = '',
  } = classes

  return {
    outer: clean(`
      ${outer}
      floating-input relative flex flex-col px-2
      formkit-invalid:bg-red-dark
      formkit-errors:bg-red-dark
      focus-within:bg-blue-highlight
    `),
    wrapper: `${wrapper} relative py-1 flex-1 flex self-start justify-center flex-col`,
    inner: 'flex ltr:pr-2 rtl:pl-2 pb-1 relative',
    block: 'flex min-h-[3.5rem] cursor-pointer formkit-disabled:cursor-default',
    input: clean(`
      ${input}
      w-full
      ltr:pl-2 rtl:pr-2
      text-sm
      bg-transparent
      border-none
      focus:outline-none
      placeholder:text-transparent
      pt-6
      formkit-label-hidden:pt-4
    `),
    label: clean(`
      ${label}
      absolute top-0 ltr:left-0 rtl:right-0
      py-4 px-2 h-14
      text-base
      transition-all duration-100 ease-in-out origin-left
      pointer-events-none
      formkit-populated:-translate-y-[0.4rem]
      formkit-populated:scale-80 formkit-populated:opacity-75
      formkit-required:required
      formkit-invalid:text-red-bright
    `),
    arrow: `${arrow} formkit-arrow flex items-center formkit-disabled:opacity-30`,
    messages: 'px-2',
  }
}
