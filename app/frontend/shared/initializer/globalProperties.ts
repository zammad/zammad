// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { App } from 'vue'
import { i18n } from '@shared/i18n'
import applicationConfigPlugin from '../plugins/applicationConfigPlugin'

export default function initializeGlobalProperties(app: App): void {
  app.config.globalProperties.i18n = i18n
  app.config.globalProperties.$t = i18n.t.bind(i18n)

  app.use(applicationConfigPlugin)

  // eslint-disable-next-line no-underscore-dangle
  app.config.globalProperties.__ = window.__
}
