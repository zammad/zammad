// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { setupCommonVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

export const initializeDesktopVisuals = () => {
  setupCommonVisualConfig({
    // TODO: for later implementation
    objectAttributes: {
      outer: 'div',
      wrapper: 'section',
      classes: {},
    },
    // TODO: should be moved to mobile only or renamed completley.
    tooltip: {
      type: 'inline',
      component: () => null,
    },
    filePreview: {
      buttonComponent: CommonButton,
      buttonProps: {
        variant: 'remove',
      },
    },
    fieldFile: {
      buttonComponent: CommonButton,
    },
  })
}
