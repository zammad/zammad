// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export type PlaceholderRenderType = 'datetime' | 'link' | 'label' | 'badge'

export interface RenderPlaceholder {
  type: PlaceholderRenderType
  props?: Record<string, unknown>
  content?: string
}
