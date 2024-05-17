// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

const defaultTheme = require('tailwindcss/defaultTheme')
const plugin = require('tailwindcss/plugin')

module.exports = plugin(
  ({ addVariant, matchUtilities, theme }) => {
    matchUtilities(
      {
        'pb-safe': (value) => ({
          paddingBottom: `calc(var(--safe-bottom, 0) + ${value})`,
        }),
        'mb-safe': (value) => ({
          marginBottom: `calc(var(--safe-bottom, 0) + ${value})`,
        }),
      },
      { values: theme('padding') },
    )

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
    addVariant('formkit-variant-submit', [
      '[data-variant="submit"] &',
      '[data-variant="submit"]&',
    ])
    addVariant('formkit-variant-danger', [
      '[data-variant="danger"] &',
      '[data-variant="danger"]&',
    ])
  },
  {
    theme: {
      extend: {
        fontFamily: {
          sans: [
            '"Fira Sans"',
            '"Helvetica Neue"',
            'Helvetica',
            'Arial',
            'sans-serif',
          ],
          mono: ['"Fira Mono"', ...defaultTheme.fontFamily.mono],
        },
        colors: {
          transparent: 'transparent',
          current: 'currentColor',
        },
        minWidth: {
          '1/2': '50%',
        },
      },
    },
  },
)
