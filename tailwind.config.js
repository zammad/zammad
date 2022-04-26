// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const colors = require('tailwindcss/colors')
const formsPlugin = require('@tailwindcss/forms')
const lineClampPlugin = require('@tailwindcss/line-clamp')
const formKitPlugin = require('@formkit/tailwindcss')
const plugin = require('tailwindcss/plugin')
const path = require('path')
const fs = require('fs')

// TODO: Move utility code elsewhere?
function* walkSync(dir) {
  const files = fs.readdirSync(dir, { withFileTypes: true })
  for (const file of files) {
    if (file.isDirectory()) {
      yield* walkSync(path.join(dir, file.name))
    } else {
      yield path.join(dir, file.name)
    }
  }
}

// Here we need to add classes which are only present in the FormSchema back end, as Tailwind
//  can't detect them otherwise.
const safelist = new Set()
for (const filePath of walkSync(`${__dirname}/app/models/form_schema/form/`)) {
  const content = fs.readFileSync(filePath).toString()
  for (const match of content.matchAll(/class: '([^']+)'/g)) {
    for (const klass of match[1].split(/[ ]+/)) {
      safelist.add(klass)
    }
  }
}

// Add the moment we can use one tailwind config for the mobile app, but later we need to check
// how this works with different apps.
module.exports = {
  content: [`${path.resolve(__dirname)}/app/frontend/**/*.{js,jsx,ts,tsx,vue}`],
  theme: {
    fontFamily: {
      sans: [
        '"Fira Sans"',
        '"Helvetica Neue"',
        'Helvetica',
        'Arial',
        'sans-serif',
      ],
    },
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      black: {
        DEFAULT: '#191919',
        full: colors.black,
      },
      white: colors.white,
      gray: {
        DEFAULT: '#999999',
        100: '#D1D1D1',
        200: '#656567',
        300: '#4C4C4D',
        400: '#323234',
        500: '#282829',
        600: '#262627',
      },
      blue: {
        DEFAULT: '#23A2CD',
        dark: '#045972',
      },
      yellow: '#FFCE33',
      red: '#E54011',
      green: '#36AF6A',
      pink: '#EA4D84',
      'dark-blue': '#045972',
      orange: '#F39804',
    },
    extend: {},
  },
  plugins: [
    formsPlugin,
    lineClampPlugin,
    formKitPlugin.default,
    plugin(({ addVariant }) => {
      addVariant('formkit-populated', [
        '&[data-populated]',
        '[data-populated] &',
        '[data-populated]&',
      ])
      addVariant('formkit-is-checked', [
        '&[data-is-checked]',
        '[data-is-checked] &',
        '[data-is-checked]&',
      ])
    }),
  ],
  safelist: [...safelist.values()],
}
