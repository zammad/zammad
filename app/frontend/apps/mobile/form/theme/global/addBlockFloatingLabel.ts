// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from './utils'
import { clean } from './utils'

/**
 * We cannot use absolute positioning for the floating label, because we might need to display
 * several rows of information on the screen - so content can depend on the actual label size and not
 * overlap.
 */
export const addBlockFloatingLabel = (classes: Classes = {}): Classes => {
  const { input = '', label = '', outer = '', wrapper = '' } = classes

  return {
    outer: `${outer} floating-input flex flex-col formkit-invalid:bg-red/10 focus-within:bg-blue-highlight px-2 `,
    wrapper: `${wrapper} relative py-1 flex-1 flex justify-center flex-col cursor-pointer`,
    inner: 'flex ltr:pr-2 rtl:pl-2 pb-1 relative',
    block: 'flex min-h-[3.5rem]',
    input: clean(`
      ${input}
      w-full
      ltr:pl-2 rtl:pr-2
      text-sm
      bg-transparent
      border-none
      focus:outline-none
      placeholder:text-transparent
      formkit-populated:pt-8
    `),
    label: clean(`
      ${label}
      flex
      cursor-pointer
      px-2 pt-1
      text-base
      transition-all duration-100 ease-in-out origin-left
      formkit-populated:text-xs formkit-populated:opacity-75
      formkit-required:required
      formkit-invalid:text-red
    `),
    arrow: 'formkit-arrow flex items-center',
  }
}
