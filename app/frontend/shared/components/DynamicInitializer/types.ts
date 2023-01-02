// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

export interface PushComponentData {
  name: string
  id: string
  cmp: Component
  props: Record<string, unknown>
}

export interface DestroyComponentData {
  name: string
  id?: string
}
