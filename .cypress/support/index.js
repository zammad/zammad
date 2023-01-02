// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import '@mobile/styles/main.scss'
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved

import './commands'

// eslint-disable-next-line no-underscore-dangle
window.__ = (str) => str

Cypress.Screenshot.defaults({ capture: 'viewport' })

if (Cypress.env('CY_CI')) {
  Cypress.config('defaultCommandTimeout', 20000)
}

beforeEach(() => document.fonts.ready)
