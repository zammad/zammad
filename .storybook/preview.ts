// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import initializeGlobalComponents from '@common/initializer/globalComponents'
import '@common/styles/main.css'
import { i18n } from '@common/utils/i18n'
import { app } from '@storybook/vue3'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import initializeStore from '@common/stores'

// adds translation to app
app.config.globalProperties.i18n = i18n
initializeGlobalComponents(app)
initializeStore(app)

export default {
  actions: { argTypesRegex: '^on[A-Z].*' },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
}
