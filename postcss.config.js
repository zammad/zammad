// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const path = require('path')
const tailwindcss = require('tailwindcss')
const autoprefixer = require('autoprefixer')

const entrypoints = path.resolve(__dirname, 'app/frontend/apps')

module.exports = {
  plugins: [
    tailwindcss(path.resolve(entrypoints, 'mobile/styles/tailwind.mobile.js')),
    tailwindcss(
      path.resolve(entrypoints, 'desktop/styles/tailwind.desktop.js'),
    ),
    autoprefixer,
  ],
}
