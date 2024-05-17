// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createSection } from '@formkit/inputs'
import { markRaw } from 'vue'

import FormFieldLink from '#shared/components/Form/FormFieldLink.vue'

import type { FormKitSchemaNode } from '@formkit/core'

export const link = createSection(
  'link',
  () =>
    ({
      $cmp: markRaw(FormFieldLink),
      if: '$link',
      props: {
        link: '$link',
        linkIcon: '$linkIcon',
      },
    }) as unknown as FormKitSchemaNode,
)
