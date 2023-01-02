// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Component } from 'vue'

interface ObjectAttributesConfig {
  outer: string | Component
  wrapper: string | Component
  classes: {
    link?: string
  }
}

export const objectAttributesConfig: ObjectAttributesConfig = {
  outer: 'div',
  wrapper: 'section',
  classes: {},
}

export const setupObjectAttributes = (
  customConfig: Partial<ObjectAttributesConfig>,
) => {
  Object.assign(objectAttributesConfig, customConfig)
}
