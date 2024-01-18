// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const tailwindcssNesting = require('tailwindcss/nesting')
const autoprefixer = require('autoprefixer')
const multipleTailwindConfigPlugin = require('./app/frontend/build/multipleTailwindConfigPlugin.js')

/** @type {import('postcss-load-config').Config} */
module.exports = {
  plugins: [
    // Vite is pre-configured to support CSS @import inlining via postcss-import.
    //   https://vitejs.dev/guide/features.html#import-inlining-and-rebasing
    tailwindcssNesting,
    multipleTailwindConfigPlugin,
    autoprefixer,
  ],
}
