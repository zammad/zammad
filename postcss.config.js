// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const path = require('path')

module.exports = {
  plugins: {
    tailwindcss: {
      config: path.resolve(__dirname, 'tailwind.config.js'),
    },
    autoprefixer: {},
  },
}
