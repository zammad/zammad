// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'

import { mountComponent, type MountOptions } from '#tests/browser/utils.ts'

export const mountEditor = (props: Record<string, unknown> = {}, options?: MountOptions) =>
  mountComponent(
    FormKit,
    {
      id: 'editor',
      name: 'editor',
      type: 'editor',
      ...props,
    },
    options,
  )
