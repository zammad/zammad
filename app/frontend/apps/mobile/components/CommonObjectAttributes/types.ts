// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type ObjectLike = Record<string, any>
export interface AttributeDeclaration {
  component: Component
  dataTypes: string[]
}
