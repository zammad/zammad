// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { en } from '@formkit/i18n'

import loadLocales from '../locales.ts'

const staticLocale = loadLocales()
const staticLocaleUI = staticLocale.ui
const staticLocaleValidation = staticLocale.validation

// This test should check if we have for all FormKit locale strings a local string
// on our side.
describe('locales', () => {
  it('check the ui strings', () => {
    Object.keys(en.ui).forEach((key) => {
      expect.soft(staticLocaleUI[key], `"${key}" is not defined`).toBeTruthy()
    })
  })

  it('check the validation strings', () => {
    Object.keys(en.validation).forEach((key) => {
      expect
        .soft(staticLocaleValidation[key], `"${key}" is not defined`)
        .toBeTruthy()
    })
  })
})
