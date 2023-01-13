// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const colors = require('tailwindcss/colors')
const lineClampPlugin = require('@tailwindcss/line-clamp')
const formKitTailwind = require('@formkit/themes/tailwindcss')
const plugin = require('tailwindcss/plugin')
const path = require('path')

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
        150: '#D8D8D8',
        200: '#656567',
        300: '#4C4C4D',
        400: '#323234',
        500: '#282829',
        600: '#262627',
        highlight: '#99999926',
        light: '#25262D99',
      },
      blue: {
        DEFAULT: '#23A2CD',
        dark: '#045972',
        highlight: '#23A2CD4D',
      },
      yellow: {
        DEFAULT: '#FFCE33',
        highlight: '#FFCE331A',
        inactive: '#A38629',
      },
      red: {
        DEFAULT: '#E54011',
        highlight: '#E540111A',
        bright: '#FF4008',
        dark: '#261F1D',
      },
      green: {
        DEFAULT: '#36AF6A',
        highlight: '#38AD691A',
      },
      pink: '#EA4D84',
      'dark-blue': '#045972',
      orange: '#F39804',
    },
    extend: {},
  },
  plugins: [
    lineClampPlugin,
    formKitTailwind,
    plugin(({ addVariant }) => {
      addVariant('formkit-populated', [
        '&[data-populated]',
        '[data-populated] &',
        '[data-populated]&',
      ])
      addVariant('formkit-required', [
        '&[data-required]',
        '[data-required] &',
        '[data-required]&',
      ])
      addVariant('formkit-dirty', [
        '&[data-dirty]',
        '[data-dirty] &',
        '[data-dirty]&',
      ])
      addVariant('formkit-is-checked', [
        '&[data-is-checked]',
        '[data-is-checked] &',
        '[data-is-checked]&',
      ])
      addVariant('formkit-label-hidden', [
        '&[data-label-hidden]',
        '[data-label-hidden] &',
        '[data-label-hidden]&',
      ])
      addVariant('formkit-variant-primary', [
        '[data-variant="primary"] &',
        '[data-variant="primary"]&',
      ])
      addVariant('formkit-variant-secondary', [
        '[data-variant="secondary"] &',
        '[data-variant="secondary"]&',
      ])
    }),
  ],
}
