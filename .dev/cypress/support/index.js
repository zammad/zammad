// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

if (Cypress.env('CY_CI')) {
  Cypress.config('defaultCommandTimeout', 20000)
}

beforeEach(() => document.fonts.ready)
