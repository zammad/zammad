// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable @typescript-eslint/no-require-imports */
const path = require('path')

const formKitTailwind = require('@formkit/themes/tailwindcss')
const containerQueriesTailwind = require('@tailwindcss/container-queries')
const unimportantTailwind = require('tailwindcss-unimportant')

const zammadTailwind = require('../../../build/zammadTailwindPlugin.js')
/* eslint-enable @typescript-eslint/no-require-imports */

const desktopDir = path.resolve(__dirname, '..')
const sharedDir = path.resolve(__dirname, '../../../shared')

/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: ['class', '[data-theme="dark"]'],
  content: [
    `${desktopDir}/**/*.{js,jsx,ts,tsx,vue,css}`,
    `${sharedDir}/**/*.{js,jsx,ts,tsx,vue,css}`,
  ],
  plugins: [
    containerQueriesTailwind,
    formKitTailwind,
    unimportantTailwind,
    zammadTailwind,
  ],
  theme: {
    colors: {
      alpha: {
        900: '#000000AA',
      },
      black: '#000000',
      white: '#FFFFFF',
      neutral: {
        50: '#FAFAFA',
        100: '#E5E5E5',
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
        200: '#FFD44C',
        300: '#FFCE33',
        500: '#FAAB00',
        600: '#F39804',
        700: '#F38612',
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
    extend: {
      width: {
        150: '600px',
      },
      minWidth: {
        58: '232px',
        150: '600px',
      },
      maxWidth: {
        150: '600px',
      },
      gridTemplateColumns: {
        '2-uneven': 'repeat(2, minmax(0, 1fr))',
      },
      zIndex: {
        60: 60,
      },
    },
  },
}
