// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { mountComponent } from '@cy/utils'

export const mountEditor = (props: Record<string, unknown> = {}) => {
  return mountComponent(FormKit, {
    props: {
      id: 'editor',
      name: 'editor',
      type: 'editor',
      ...props,
    },
  })
}
