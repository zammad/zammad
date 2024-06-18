// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

export interface FilePreviewClassMap {
  base: string
  wrapper: string
  preview: string
  link: string
  icon: string
  size: string
}

export interface FilePreviewVisualConfig {
  buttonComponent: Component
  buttonProps?: Record<string, unknown>
}
