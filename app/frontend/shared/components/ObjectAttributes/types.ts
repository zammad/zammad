// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { OperationMutationFunction } from '#shared/types/server/apollo/handler.ts'

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

export type InlineEditable = Record<string, OperationMutationFunction>

export interface ObjectAttributeProps<T, V> {
  attribute: T
  value: V
  mode: OutputMode
  config?: ObjectAttributesConfig
  inlineEditable?: InlineEditable
}
