// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitSchemaNode } from '@formkit/core'
import { createSection } from '@formkit/inputs'

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
