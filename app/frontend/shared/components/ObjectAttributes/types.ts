// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

export type OutputMode = 'table' | 'view'

export interface AttributeDeclaration {
  component: Component
  dataTypes: string[]
}

export interface ObjectAttributesConfig {
  outer: string | Component
  wrapper: string | Component
  classes: {
    link?: string
  }
}

export interface ObjectAttributeProps<T, V> {
  attribute: T
  value: V
  mode: OutputMode
  config?: ObjectAttributesConfig
}
