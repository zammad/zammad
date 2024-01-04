// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from './utils.ts'
import { clean, extendClasses } from './utils.ts'

/**
 * Textarea can be scrolled, so if we use "aboslute" positioning for label,
 * it will overlap with textarea content. But we still can't use regular solution,
 * becase the label text should be on the same row with the textarea, so we have a trick,
 * where we use "h-2", so it overlaps with the content, until the textarea is populated.
 */
export const addFloatingTextareaLabel = (classes: Classes = {}) => {
  return extendClasses(classes, {
    outer: clean(`
      floating-textarea relative px-2
    `),
    wrapper: 'relative',
    // text-base ensures there is no zoom when you click on the input on iOS
    input: clean(`
      w-full
      text-base
      bg-transparent
      border-none
      focus:outline-none
      placeholder:text-transparent
    `),
    label: clean(`
      flex
      items-end
      px-2
      pt-5
      h-2
      translate-y-4
      text-base
      cursor-text
      transition-all duration-100 ease-in-out origin-left
      formkit-populated:translate-y-0 formkit-populated:text-xs formkit-populated:opacity-75
    `),
  })
}
