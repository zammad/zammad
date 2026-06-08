// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

let buttonGroup: Component | null = null

export const initButtonGroup = (cmp: Component) => {
  buttonGroup = cmp
}

export const getButtonGroup = () => buttonGroup
