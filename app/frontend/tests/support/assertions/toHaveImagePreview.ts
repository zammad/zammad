// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { getTestState } from '../utils.ts'

export default function toHaveImagePreview(
  this: any,
  received: unknown,
  content: string,
) {
  const state = getTestState()
  const currentContent =
    state.imageViewerOptions &&
    state.imageViewerOptions.value.images[state.imageViewerOptions.value.index]
      .src
  const pass = currentContent === content
  return {
    pass,
    message: () =>
      `expected current image preview${
        this.isNot ? ' not' : ''
      } to be ${content}, but got ${currentContent}`,
  }
}
