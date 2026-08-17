// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { TooltipVisualConfig } from '#shared/components/CommonTooltip/types.ts'
import type { FieldFileVisualConfig } from '#shared/components/Form/fields/FieldFile/types.ts'
import type { ObjectAttributesConfig } from '#shared/components/ObjectAttributes/types.ts'

export interface SharedVisualConfig {
  objectAttributes: ObjectAttributesConfig
  tooltip: TooltipVisualConfig
  fieldFile?: FieldFileVisualConfig
}

const currentVisualConfig: SharedVisualConfig = {
  objectAttributes: {
    outer: 'div',
    wrapper: 'section',
    classes: {},
  },
  tooltip: {
    type: 'inline',
    component: () => null,
  },
  fieldFile: {
    buttonComponent: () => null,
    listComponent: () => null,
  },
}

export const useSharedVisualConfig = () => {
  return currentVisualConfig
}

export const setupCommonVisualConfig = (config: SharedVisualConfig) => {
  Object.assign(currentVisualConfig, config)
}
