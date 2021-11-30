import { app } from '@storybook/vue3';
import { i18n } from '@common/utils/i18n';

// adds translation to app
app.config.globalProperties.i18n = i18n

export const parameters = {
  actions: { argTypesRegex: "^on[A-Z].*" },
  controls: {
    matchers: {
      color: /(background|color)$/i,
      date: /Date$/,
    },
  },
}