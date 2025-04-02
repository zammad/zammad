// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import Default from '../CellContent/Default.vue'
import Timestamp from '../CellContent/Timestamp.vue'
import TimestampAbsolute from '../CellContent/TimestampAbsolute.vue'

import type { Component } from 'vue'

export const useCellContent = () => {
  const typeComponents: Record<string, Component> = {
    default: Default,
    timestamp: Timestamp,
    timestamp_absolute: TimestampAbsolute,
  }

  const getCellContentComponent = (headerType?: string) => {
    if (headerType && typeComponents[headerType]) {
      return typeComponents[headerType]
    }

    return typeComponents.default
  }

  return {
    getCellContentComponent,
  }
}
