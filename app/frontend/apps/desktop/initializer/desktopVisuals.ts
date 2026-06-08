// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { initButtonGroup } from '#shared/components/ObjectAttributes/attributes/AttributeRichtext/initializeRichtextButtons.ts'
import { setupCommonVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonInlineEditButtons from '#desktop/components/CommonInlineEditButtons/CommonInlineEditButtons.vue'
import CommonObjectAttribute from '#desktop/components/CommonObjectAttribute/CommonObjectAttribute.vue'
import CommonObjectAttributeContainer from '#desktop/components/CommonObjectAttribute/CommonObjectAttributeContainer.vue'

export const initializeDesktopVisuals = () => {
  setupCommonVisualConfig({
    // TODO: for later implementation
    objectAttributes: {
      outer: CommonObjectAttributeContainer,
      wrapper: CommonObjectAttribute,
      classes: {
        link: 'text-sm',
      },
    },
    // TODO: should be moved to mobile only or renamed completely.
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

  initButtonGroup(CommonInlineEditButtons)
}
