// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FilePreviewVisualConfig } from '#shared/components/CommonFilePreview/types.ts'
import type { TooltipVisualConfig } from '#shared/components/CommonTooltip/types.ts'
import type { FieldFileVisualConfig } from '#shared/components/Form/fields/FieldFile/types.ts'
import type { ObjectAttributesConfig } from '#shared/components/ObjectAttributes/types.ts'

export interface SharedVisualConfig {
  objectAttributes: ObjectAttributesConfig
  tooltip: TooltipVisualConfig
  filePreview?: FilePreviewVisualConfig
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
  filePreview: {
    buttonComponent: () => null,
    buttonProps: {},
  },
  fieldFile: {
    buttonComponent: () => null,
  },
}

export const useSharedVisualConfig = () => {
  return currentVisualConfig
}

export const setupCommonVisualConfig = (config: SharedVisualConfig) => {
  Object.assign(currentVisualConfig, config)
}
