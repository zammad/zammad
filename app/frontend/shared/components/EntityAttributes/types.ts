// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { OperationMutationFunction } from '#shared/types/server/apollo/handler.ts'

import type { Component } from 'vue'

export type OutputMode = 'table' | 'view'

export interface AttributeDeclaration {
  component: Component
  dataTypes: string[]
}

export interface EntityAttributesConfig {
  outer: string | Component
  wrapper: string | Component
  classes: {
    link?: string
  }
}

export type InlineEditable = Record<string, OperationMutationFunction>

export interface EntityAttributeProps<T, V> {
  attribute: T
  value: V
  mode: OutputMode
  config?: EntityAttributesConfig
  inlineEditable?: InlineEditable
}
