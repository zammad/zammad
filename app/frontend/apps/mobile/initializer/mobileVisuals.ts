// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '#mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import { setupCommonVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'

export const initializeMobileVisuals = () => {
  setupCommonVisualConfig({
    objectAttributes: {
      outer: CommonSectionMenu,
      wrapper: CommonSectionMenuItem,
      classes: {
        link: 'cursor-pointer text-blue',
      },
    },
    tooltip: {
      type: 'popup',
      component: CommonSectionPopup,
    },
  })
}
