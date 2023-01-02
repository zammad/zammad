// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { createSection } from '@formkit/inputs'
import { markRaw } from 'vue'
import FormFieldLink from '@shared/components/Form/FormFieldLink.vue'
import type { FormKitSchemaNode } from '@formkit/core'

export const link = createSection(
  'link',
  () =>
    ({
      $el: 'div',
      if: '$link',
      attrs: {
        class: 'formkit-link flex items-center py-2',
      },
      children: [
        {
          $cmp: markRaw(FormFieldLink),
          props: {
            link: '$link',
          },
        },
      ],
    } as unknown as FormKitSchemaNode),
)
