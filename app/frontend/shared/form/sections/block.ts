// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createSection } from '@formkit/inputs'

export const block = createSection('block', () => {
  return {
    $el: 'div',
    attrs: {
      onClick: "$handlers.bindEmit('block-click')",
    },
  }
})
