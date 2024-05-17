// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const path = require('path')

const formKitTailwind = require('@formkit/themes/tailwindcss')
const colors = require('tailwindcss/colors')

const zammadTailwind = require('../../../build/zammadTailwindPlugin.js')

const mobileDir = path.resolve(__dirname, '..')
const sharedDir = path.resolve(__dirname, '../../../shared')

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    `${mobileDir}/**/*.{js,jsx,ts,tsx,vue,css}`,
    `${sharedDir}/**/*.{js,jsx,ts,tsx,vue,css}`,
  ],
  plugins: [formKitTailwind, zammadTailwind],
  theme: {
    colors: {
      pink: {
        DEFAULT: '#EA4D84',
        bright: '#FF006B',
      },
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
        highlight: '#23A2CD19',
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
      orange: '#F39804',
    },
  },
}
