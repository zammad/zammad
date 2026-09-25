// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable @typescript-eslint/no-require-imports */
const defaultTheme = require('tailwindcss/defaultTheme')
const plugin = require('tailwindcss/plugin')
/* eslint-enable @typescript-eslint/no-require-imports */

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
    addVariant('formkit-required', ['&[data-required]', '[data-required] &', '[data-required]&'])
    addVariant('formkit-dirty', ['&[data-dirty]', '[data-dirty] &', '[data-dirty]&'])
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
    addVariant('formkit-variant-submit', ['[data-variant="submit"] &', '[data-variant="submit"]&'])
    addVariant('formkit-variant-danger', ['[data-variant="danger"] &', '[data-variant="danger"]&'])
    addVariant('formkit-warning', [
      '&[data-message-type="warning"]',
      '[data-message-type="warning"] &',
      '[data-message-type="warning"]&',
    ])
    addVariant('formkit-alternative-background', [
      '&[data-alternative-background]',
      '[data-alternative-background] &',
      '[data-alternative-background]&',
    ])
  },
  {
    theme: {
      extend: {
        fontFamily: {
          sans: ['"Fira Sans"', '"Helvetica Neue"', 'Helvetica', 'Arial', 'sans-serif'],
          mono: ['"Fira Mono"', ...defaultTheme.fontFamily.mono],
        },
        colors: {
          transparent: 'transparent',
          current: 'currentColor',
        },
        minWidth: {
          '1/2': '50%',
        },
        keyframes: {
          // A ringing phone: a burst of swings, then a pause before it rings again.
          vibrate: {
            '0%, 47%, 100%': { transform: 'rotate(0) translate(0)' },
            '3%, 9%, 15%, 21%, 27%, 33%, 39%': {
              transform: 'rotate(-2deg) translateX(-1px)',
            },
            '6%, 12%, 18%, 24%, 30%, 36%, 42%': {
              transform: 'rotate(10deg) translateX(1px)',
            },
          },
        },
        animation: {
          'ping-once': 'ping .3s cubic-bezier(0, 0, 0.2, 1)',
          vibrate: 'vibrate 3s ease-in-out infinite',
        },
      },
    },
  },
)
