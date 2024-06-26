// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from '#shared/form/plugins/utils.ts'
import { clean, extendClasses } from '#shared/form/plugins/utils.ts'

/**
 * Textarea can be scrolled, so if we use "aboslute" positioning for label,
 * it will overlap with textarea content. But we still can't use regular solution,
 * becase the label text should be on the same row with the textarea, so we have a trick,
 * where we use "h-2", so it overlaps with the content, until the textarea is populated.
 */
export const addFloatingTextareaLabel = (classes: Classes = {}) => {
  return extendClasses(classes, {
    outer: clean(`floating-textarea relative px-2`),
    wrapper: 'relative',
    // text-base ensures there is no zoom when you click on the input on iOS
    input: clean(
      `w-full border-none bg-transparent text-base placeholder:text-transparent focus:outline-none`,
    ),
    label: clean(
      `formkit-populated:translate-y-0 formkit-populated:text-xs formkit-populated:opacity-75 flex h-2 origin-left translate-y-4 cursor-text items-end px-2 pt-5 text-base transition-all duration-100 ease-in-out`,
    ),
  })
}
