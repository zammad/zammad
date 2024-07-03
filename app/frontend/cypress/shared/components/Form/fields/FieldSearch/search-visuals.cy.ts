// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `pnpm cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '#cy/utils.ts'

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

  it(`renders hidden search`, () => {
    mountFormField('search', { label: 'search', labelSrOnly: true })
    checkFormMatchesSnapshot()
    cy.get('input')
      .type(input)
      .then(() => {
        checkFormMatchesSnapshot({ subTitle: 'filled' })
      })
  })
})
