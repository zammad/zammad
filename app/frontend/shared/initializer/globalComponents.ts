// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import { FormKit } from '@formkit/vue'
import CommonIcon from '@shared/components/CommonIcon/CommonIcon.vue'
import CommonLink from '@shared/components/CommonLink/CommonLink.vue'
import CommonDateTime from '@shared/components/CommonDateTime/CommonDateTime.vue'

declare module '@vue/runtime-core' {
  export interface GlobalComponents {
    CommonIcon: typeof CommonIcon
    CommonLink: typeof CommonLink
    CommonDateTime: typeof CommonDateTime
    FormKit: typeof FormKit
  }
}

export default function initializeGlobalComponents(app: App): void {
  app.component('CommonIcon', CommonIcon)
  app.component('CommonLink', CommonLink)
  app.component('CommonDateTime', CommonDateTime)
}
