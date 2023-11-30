// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const colors = require('tailwindcss/colors')
const formKitTailwind = require('@formkit/themes/tailwindcss')
const path = require('path')
const daisyTailwind = require('daisyui')
const themes = require('daisyui/src/theming/themes.js')

const zammadTailwind = require('../../../build/zammadTailwindPlugin.js')

const desktopDir = path.resolve(__dirname, '..')
const sharedDir = path.resolve(__dirname, '../../../shared')

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class', '[data-theme="dark"]'],
  content: [
    `${desktopDir}/**/*.{js,jsx,ts,tsx,vue}`,
    `${sharedDir}/**/*.{js,jsx,ts,tsx,vue}`,
  ],
  plugins: [formKitTailwind, zammadTailwind, daisyTailwind],
  daisyui: {
    logs: false,
    // daisy ui is used only in desktop, so its classes CANNOT be used in "shared"
    // https://daisyui.com/docs/themes/#-7
    themes: [
      // 4 base bg colors:
      // light: #FFFFFF, (neutral) #F9FAFB, #E5E5E5, #EDF1F2
      // dark: #323234, (neutral) #212122, #505052, #262627

      // buttons/links:
      // "primary" - blue
      // "secondary" - "light-blue" (usually a higlight color)
      // "accent" - yellow
      {
        light: {
          ...themes.light,
          // base is usually backgrounds
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=0-1&mode=design&t=b8SYVpqnggUOnkI4-0 (middle sidebar bg and always default bg)
          'base-100': '#F9FAFB',
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=1-65700&mode=design&t=b8SYVpqnggUOnkI4-0 (inputs/links/tags bg, etc.)
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=0-1&mode=design&t=b8SYVpqnggUOnkI4-0 (higlighted bg in table)
          'base-200': '#EDF1F2',
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=0-1&mode=design&t=b8SYVpqnggUOnkI4-0 (middle sidebar border)
          'base-300': '#E5E5E5',
          // text color on "base" backgrounds
          'base-content': '#585856',
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=1-65700&mode=design&t=b8SYVpqnggUOnkI4-0 (right sidebar and blocks)
          neutral: '#FFFFFF',

          primary: '#23A2CD',
          secondary: '#045972',
          accent: '#FFCE33',
          'accent-content': colors.black,

          error: '#E54011',
          warning: '#F39804',
          success: '#36AF6A',
          info: '#23A2CD',
        },
      },
      {
        dark: {
          ...themes.dark,
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=0-1&mode=design&t=b8SYVpqnggUOnkI4-0 (middle sidebar bg and always default bg)
          'base-100': '#212122',
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=1-65700&mode=design&t=b8SYVpqnggUOnkI4-0 (inputs/links/tags bg, etc.)
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=0-1&mode=design&t=b8SYVpqnggUOnkI4-0 (higlighted bg in table)
          'base-200': '#262627',
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=0-1&mode=design&t=b8SYVpqnggUOnkI4-0 (middle sidebar border)
          'base-300': '#505052',
          // text color on "base" backgrounds
          'base-content': '#D1D1D1',
          // https://www.figma.com/file/DcIjH8I28Y5uWPv61SprqK/Screens?type=design&node-id=1-65700&mode=design&t=b8SYVpqnggUOnkI4-0 (right sidebar and blocks)
          neutral: '#323234',

          primary: '#23A2CD',
          secondary: '#045972',
          accent: '#FFCE33',

          error: '#E54011',
          warning: '#F39804',
          success: '#36AF6A',
          info: '#23A2CD',
        },
      },
    ],
  },
}
