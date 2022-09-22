// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Classes } from './utils'
import { clean } from './utils'

/**
 * Textarea can be scrolled, so if we use "aboslute" positioning for label,
 * it will overlap with textarea content. But we still can't use regular solution,
 * becase the label text should be on the same row with the textarea, so we have a trick,
 * where we use "h-2", so it overlaps with the content, until the textarea is populated.
 */
export const addFloatingTextareaLabel = (classes: Classes = {}) => {
  const {
    input = '',
    label = '',
    inner = '',
    outer = '',
    wrapper = '',
  } = classes

  return {
    outer: `${outer} floating-textarea px-2`,
    wrapper: `${wrapper} formkit-invalid:bg-red/10 relative`,
    inner,
    input: clean(`
      ${input}
      w-full
      text-sm
      bg-transparent
      border-none
      focus:outline-none
      placeholder:text-transparent
    `),
    label: clean(`
      ${label}
      flex
      items-end
      px-2
      pt-5
      h-2
      translate-y-4
      text-base
      transition-all duration-100 ease-in-out origin-left
      formkit-populated:translate-y-0
      formkit-populated:text-xs formkit-populated:opacity-75
      formkit-required:required
      formkit-invalid:text-red
    `),
  }
}
