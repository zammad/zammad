// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const formKitTailwind = require('@formkit/themes/tailwindcss')
const path = require('path')
const zammadTailwind = require('../../../build/zammadTailwindPlugin.js')

const mobileDir = path.resolve(__dirname, '..')
const sharedDir = path.resolve(__dirname, '../../../shared')

module.exports = {
  content: [
    `${mobileDir}/**/*.{js,jsx,ts,tsx,vue}`,
    `${sharedDir}/**/*.{js,jsx,ts,tsx,vue}`,
  ],
  plugins: [formKitTailwind, zammadTailwind],
}
