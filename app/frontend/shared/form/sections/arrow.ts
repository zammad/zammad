// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitSchemaNode } from '@formkit/core'
import { createSection } from '@formkit/inputs'
import { useLocaleStore } from '@shared/stores/locale'

export const arrow = createSection('arrow', () => {
  const locale = useLocaleStore()

  return {
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
          name: `mobile-chevron-${
            locale.localeData?.dir === 'rtl' ? 'left' : 'right'
          }`,
          decorative: true,
        },
      },
    ],
  } as FormKitSchemaNode
})
