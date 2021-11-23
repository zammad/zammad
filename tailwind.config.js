// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

const formsPlugin = require('@tailwindcss/forms')

module.exports = {
  content: [
    './app/frontend/**/*.{js,jsx,ts,tsx,vue}',
    './app/views/mobile/index.html.erb',
  ],
  theme: {
    extend: {
      colors: {
        // TODO: only first testing colors
        darker: '#25262d',
        dark: '#2c2d35',
      },
    },
  },
  plugins: [formsPlugin],
}
