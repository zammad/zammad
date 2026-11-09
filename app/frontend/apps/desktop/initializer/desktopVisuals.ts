// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { initButtonGroup } from '#shared/components/EntityAttributes/attributes/AttributeRichtext/initializeRichtextButtons.ts'
import { setupCommonVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonEntityAttribute from '#desktop/components/CommonEntityAttribute/CommonEntityAttribute.vue'
import CommonEntityAttributeContainer from '#desktop/components/CommonEntityAttribute/CommonEntityAttributeContainer.vue'
import CommonInlineEditButtons from '#desktop/components/CommonInlineEditButtons/CommonInlineEditButtons.vue'
import FieldFileList from '#desktop/components/Form/fields/FieldFile/FieldFileList.vue'

export const initializeDesktopVisuals = () => {
  setupCommonVisualConfig({
    // TODO: for later implementation
    entityAttributes: {
      outer: CommonEntityAttributeContainer,
      wrapper: CommonEntityAttribute,
      classes: {
        link: 'text-sm',
      },
    },
    // TODO: should be moved to mobile only or renamed completely.
    tooltip: {
      type: 'inline',
      component: () => null,
    },
    fieldFile: {
      buttonComponent: CommonButton,
      listComponent: FieldFileList,
    },
  })

  initButtonGroup(CommonInlineEditButtons)
}
