// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import '#mobile/styles/main.scss'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved

import './commands.js'

// @testing-library/cypress uses env to display errors
globalThis.process.env = {
  DEBUG_PRINT_LIMIT: 5000,
}

// eslint-disable-next-line no-underscore-dangle
window.__ = (str) => str

Cypress.Screenshot.defaults({ capture: 'viewport' })

if (Cypress.env('CY_CI')) {
  Cypress.config('defaultCommandTimeout', 20000)
}

beforeEach(() => document.fonts.ready)
