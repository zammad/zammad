// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

const colors = require('tailwindcss/colors')
const formsPlugin = require('@tailwindcss/forms')
const lineClampPlugin = require('@tailwindcss/line-clamp')

// Add the moment we can use one tailwind config for the mobile app, but later we need to check
// how this works with different apps.
module.exports = {
  content: ['./app/frontend/**/*.{js,jsx,ts,tsx,vue}'],
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
        100: '#4C4C4D',
        200: '#323234',
        300: '#282829',
        400: '#262627',
      },
      blue: {
        DEFAULT: '#23A2CD',
        dark: '#045972',
      },
      yellow: '#FFCE33',
      red: '#E54011',
      green: '#36AF6A',
    },
    extend: {},
  },
  plugins: [formsPlugin, lineClampPlugin],
}
