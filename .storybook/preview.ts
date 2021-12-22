// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

import { app } from '@storybook/vue3'
import { i18n } from '@common/utils/i18n'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import '@common/styles/main.css'
import initializeGlobalComponents from '@common/initializer/globalComponents'

// adds translation to app
app.config.globalProperties.i18n = i18n
initializeGlobalComponents(app)

export default {
  actions: { argTypesRegex: '^on[A-Z].*' },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
}
