// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

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
  config?: ObjectAttributesConfig
}
