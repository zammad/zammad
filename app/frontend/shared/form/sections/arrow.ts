// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
          fixedSize: { width: 24, height: 24 },
          class: 'shrink-0',
          name: `chevron-${
            locale.localeData?.dir === 'rtl' ? 'left' : 'right'
          }`,
          decorative: true,
        },
      },
    ],
  } as FormKitSchemaNode
})
