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
  plugins: [
    formKitTailwind,
    zammadTailwind,
    daisyTailwind,
    ({ addComponents, theme }) => {
      addComponents({
        // NB: Used by FieldDateTimeInput.vue component, within its style section.
        //   Since all component styles are processed in isolation, we have to provide the classes below within the
        //   configuration, otherwise we risk running into build issues since class definitions in imported stylesheets
        //   might not be available.
        '.date-selection': {
          borderColor: theme('colors.blue.800'),
          backgroundColor: theme('colors.blue.800'),
          backgroundImage: 'none',
        },
        '.date-navigation': {
          color: theme('colors.blue.800'),
        },
      })
    },
  ],
  theme: {
    colors: {
      alpha: {
        100: '#EDF1F280',
        800: '#33343880',
      },
      black: '#000000',
      white: '#FFFFFF',
      neutral: {
        100: '#E6E6E6',
        200: '#E3E3E3',
        300: '#DCDCDC',
        400: '#D1D1D1',
        500: '#999999',
        950: '#191919',
      },
      gray: {
        100: '#585856',
        200: '#535355',
        300: '#434141',
        400: '#3F3F41',
        500: '#323234',
        600: '#2C2C2D',
        700: '#262627',
        800: '#212122',
        900: '#202021',
      },
      stone: {
        200: '#A0A3A6',
        300: '#A0A3A6',
        400: '#6F7071',
        500: '#4B5058',
        700: '#383B41',
      },
      blue: {
        50: '#F9FAFB',
        100: '#E5F0F5',
        200: '#EDF1F2',
        300: '#D4E2E9',
        400: '#C9E1EA',
        500: '#C0DDE6',
        600: '#7FD4F1',
        700: '#49A9CA',
        800: '#23A2CD',
        900: '#045972',
        950: '#063849',
      },
      green: {
        100: '#EFF0F1',
        200: '#BCCED2',
        300: '#BBE0CB',
        400: '#38AD69',
        500: '#36AF6A',
        900: '#07341A',
      },
      yellow: {
        50: '#FFF6DA',
        300: '#FFCE33',
        400: '#FFCE33',
        500: '#FAAB00',
        600: '#F39804',
        800: '#4A3300',
        900: '#453914',
      },
      red: {
        50: '#FAEFD6',
        300: '#F35912',
        400: '#E9613A',
        500: '#E54011',
        600: '#86270C',
        900: '#220C06',
      },
      pink: {
        100: '#EFD9D2',
        300: '#EA4D84',
        500: '#FF006B',
      },
    },
  },
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
