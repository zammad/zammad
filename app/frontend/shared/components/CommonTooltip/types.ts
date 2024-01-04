// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

export interface TooltipVisualConfig {
  type: 'popup' | 'inline'
  component: Component
}

export interface TooltipItemDescriptor {
  label: string
  type: 'button' | 'link' | 'text'
  link?: string
}
