// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import './prepare.js'

import '#mobile/styles/main.css'
import '#shared/components/CommonIcon/injectIcons.ts'

import '../../../public/assets/frontend/fonts.css'

import './commands.js'

// @testing-library/cypress uses env to display errors
globalThis.process.env = {
  DEBUG_PRINT_LIMIT: 5000,
}

Cypress.Screenshot.defaults({ capture: 'viewport' })

// Benign browser warning when a resize observer callback changes the layout again.
Cypress.on('uncaught:exception', (err) => {
  // eslint-disable-next-line zammad/zammad-detect-translatable-string
  if (err.message.includes('ResizeObserver loop')) return false
})

if (Cypress.expose('CY_CI')) {
  Cypress.config('defaultCommandTimeout', 20000)
}

beforeEach(() => document.fonts.ready)
