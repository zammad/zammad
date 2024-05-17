// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const { minimatch } = require('minimatch')
const tailwindcss = require('tailwindcss')

const desktopConfig = require('../apps/desktop/styles/tailwind.desktop.js')
const mobileConfig = require('../apps/mobile/styles/tailwind.mobile.js')

/** @type {import('postcss').TransformCallback} */
module.exports = (root, result) => {
  // Check the current module against content globs in available app-specific Tailwind configs.
  //   This avoids the build issue with the wrong Tailwind config being applied.
  if (
    mobileConfig.content.some((glob) => minimatch(root.source.input.file, glob))
  )
    return tailwindcss(mobileConfig).plugins[0](root, result)

  return tailwindcss(desktopConfig).plugins[0](root, result)
}
