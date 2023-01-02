// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { setupObjectAttributes } from '@shared/components/ObjectAttributes/config'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '@mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'

export const initializeObjectAttributes = () => {
  setupObjectAttributes({
    outer: CommonSectionMenu,
    wrapper: CommonSectionMenuItem,
    classes: {
      link: 'cursor-pointer text-blue',
    },
  })
}
