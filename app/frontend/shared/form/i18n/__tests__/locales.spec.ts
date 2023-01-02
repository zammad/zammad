// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { en } from '@formkit/i18n'
import loadLocales from '../locales'

const staticLocale = loadLocales()
const staticLocaleUI = staticLocale.ui
const staticLocaleValidation = staticLocale.validation

// This test should check if we have for all FormKit locale strings a local string
// on our side.
describe('locales', () => {
  it('check the ui strings', () => {
    Object.keys(en.ui).forEach((key) => {
      if (!staticLocaleUI[key]) {
        console.log(`Missing form kit ui string "${key}".`)
      }
      expect(staticLocaleUI[key]).toBeTruthy()
    })
  })

  it('check the validation strings', () => {
    Object.keys(en.validation).forEach((key) => {
      expect(staticLocaleValidation[key]).toBeTruthy()
    })
  })
})
