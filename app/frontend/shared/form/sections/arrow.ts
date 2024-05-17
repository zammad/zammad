// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createSection } from '@formkit/inputs'

import type { FormKitSchemaNode } from '@formkit/core'

export const arrow = createSection(
  'arrow',
  () =>
    ({
      $el: 'div',
      attrs: {
        class: '$classes.arrow',
      },
      children: [
        {
          $cmp: 'CommonIcon',
          props: {
            size: 'base',
            class: 'shrink-0',
            name: '$arrowIconName',
            decorative: true,
          },
        },
      ],
    }) as FormKitSchemaNode,
)
