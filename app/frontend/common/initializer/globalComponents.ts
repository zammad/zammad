// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import CommonIcon from '@common/components/common/CommonIcon.vue'
import CommonLink from '@common/components/common/CommonLink.vue'

declare module '@vue/runtime-core' {
  export interface GlobalComponents {
    CommonIcon: typeof CommonIcon
    CommonLink: typeof CommonLink
  }
}

export default function initializeGlobalComponents(app: App): void {
  app.component('CommonIcon', CommonIcon)
  app.component('CommonLink', CommonLink)
}
