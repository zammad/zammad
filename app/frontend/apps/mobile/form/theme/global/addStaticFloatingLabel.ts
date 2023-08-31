// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from './utils.ts'
import { clean } from './utils.ts'

/**
 * We cannot use absolute positioning for the floating label, because we might need to display
 * several rows of information on the screen - so content can depend on the actual label size and not
 * overlap.
 */
export const addStaticFloatingLabel = (classes: Classes = {}): Classes => {
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
      relative flex flex-col px-2
      formkit-invalid:bg-red-dark
      formkit-errors:bg-red-dark
      focus-within:bg-blue-highlight
    `),
    wrapper: `${wrapper} relative py-1 flex-1 flex self-start justify-center flex-col`,
    inner: 'flex ltr:pr-2 rtl:pl-2 pb-1 relative',
    block: 'flex min-h-[3.5rem] cursor-pointer formkit-disabled:cursor-default',
    // text-base ensures there is no zoom when you click on the input on iOS
    input: clean(`
      ${input}
      w-full
      ltr:pl-2 rtl:pr-2
      text-base
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
      transition-all duration-100 ease-in-out origin-left
      pointer-events-none
      -translate-y-[0.4rem]
      scale-80
      text-xs
      formkit-required:required
      formkit-invalid:text-red-bright

    `),
    help: 'px-2 pb-2',
    arrow: `${arrow} formkit-arrow flex items-center formkit-disabled:opacity-30`,
    messages: 'px-2',
    suffixIcon: 'text-white fill-current flex justify-center items-center',
  }
}
