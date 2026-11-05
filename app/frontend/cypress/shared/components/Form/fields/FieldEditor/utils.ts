// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'

import { mountComponent } from '#cy/utils.ts'

export const mountEditor = (
  props: Record<string, unknown> = {},
  permissions?: string[],
  config?: Record<string, unknown>,
) => {
  return mountComponent(FormKit, {
    props: {
      id: 'editor',
      name: 'editor',
      type: 'editor',
      ...props,
    },
    permissions,
    config,
  })
}

// ProseMirror renders `img.ProseMirror-separator` cursor helpers next to inline atoms.
export const EDITOR_IMAGE = 'img:not(.ProseMirror-separator)'
