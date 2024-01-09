// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const tailwindcss = require('tailwindcss')
const autoprefixer = require('autoprefixer')
const mobileConfig = require('./app/frontend/apps/mobile/styles/tailwind.mobile.js')

module.exports = {
  plugins: [tailwindcss(mobileConfig), autoprefixer],
}
