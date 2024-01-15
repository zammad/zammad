// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const tailwindcssNesting = require('tailwindcss/nesting')
const tailwindcss = require('tailwindcss')
const autoprefixer = require('autoprefixer')
const mobileConfig = require('./app/frontend/apps/mobile/styles/tailwind.mobile.js')
const desktopConfig = require('./app/frontend/apps/desktop/styles/tailwind.desktop.js')

module.exports = {
  plugins: [
    // Vite is pre-configured to support CSS @import inlining via postcss-import.
    //   https://vitejs.dev/guide/features.html#import-inlining-and-rebasing
    tailwindcssNesting,
    tailwindcss(mobileConfig),
    tailwindcss(desktopConfig),
    autoprefixer,
  ],
}
