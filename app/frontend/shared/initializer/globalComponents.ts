// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import CommonAlert from '#shared/components/CommonAlert/CommonAlert.vue'
import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonLink from '#shared/components/CommonLink/CommonLink.vue'

import type { FormKit } from '@formkit/vue'
import type { App } from 'vue'
import type { RouterLink, RouterView } from 'vue-router'

declare module '@vue/runtime-core' {
  export interface GlobalComponents {
    CommonAlert: typeof CommonAlert
    CommonIcon: typeof CommonIcon
    CommonLink: typeof CommonLink
    CommonDateTime: typeof CommonDateTime
    CommonBadge: typeof CommonBadge
    CommonLabel: typeof CommonLabel
    FormKit: typeof FormKit

    RouterView: typeof RouterView
    RouterLink: typeof RouterLink
  }
}

export default function initializeGlobalComponents(app: App): void {
  app.component('CommonAlert', CommonAlert)
  app.component('CommonIcon', CommonIcon)
  app.component('CommonLink', CommonLink)
  app.component('CommonDateTime', CommonDateTime)
  app.component('CommonLabel', CommonLabel)
  app.component('CommonBadge', CommonBadge)
}
