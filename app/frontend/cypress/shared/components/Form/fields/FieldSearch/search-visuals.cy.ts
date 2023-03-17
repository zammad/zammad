// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'

describe('testing visuals for "FieldSearch"', () => {
  const input = 'search test'

  it(`renders usual search`, () => {
    mountFormField('search', { label: 'search' })
    checkFormMatchesSnapshot()
    cy.get('input')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot({ subTitle: 'focused' })
      })
    cy.get('input')
      .type(input)
      .then(() => {
        checkFormMatchesSnapshot({ subTitle: 'filled' })
      })
  })

  it(`renders disabled search`, () => {
    mountFormField('search', { label: 'search', disabled: true })
    checkFormMatchesSnapshot()
  })
})
