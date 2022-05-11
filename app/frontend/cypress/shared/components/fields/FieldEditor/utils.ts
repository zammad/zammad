// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import { mountComponent } from '@cy/utils'

export const mountEditor = (props: Record<string, unknown> = {}) => {
  return mountComponent(FormKit, {
    props: {
      name: 'editor',
      type: 'editor',
      ...props,
    },
  })
}

export default {}
