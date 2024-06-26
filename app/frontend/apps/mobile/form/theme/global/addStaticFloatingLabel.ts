// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from '#shared/form/plugins/utils.ts'
import { clean, extendClasses } from '#shared/form/plugins/utils.ts'

/**
 * We cannot use absolute positioning for the floating label, because we might need to display
 * several rows of information on the screen - so content can depend on the actual label size and not
 * overlap.
 */
export const addStaticFloatingLabel = (classes: Classes = {}): Classes => {
  return extendClasses(classes, {
    outer: clean(`focus-within:bg-blue-highlight relative flex flex-col px-2`),
    wrapper: 'relative flex flex-1 flex-col justify-center self-start py-1',
    inner: 'relative flex pb-1 ltr:pr-2 rtl:pl-2',
    block: 'formkit-disabled:cursor-default flex min-h-[3.5rem] cursor-pointer',
    // text-base ensures there is no zoom when you click on the input on iOS
    input: clean(
      `formkit-label-hidden:pt-4 w-full border-none bg-transparent pt-6 text-base placeholder:text-transparent focus:outline-none ltr:pl-2 rtl:pr-2`,
    ),
    label: clean(
      `pointer-events-none absolute top-0 h-14 origin-left px-2 py-4 transition-all duration-100 ease-in-out ltr:left-0 rtl:right-0`,
    ),
  })
}
