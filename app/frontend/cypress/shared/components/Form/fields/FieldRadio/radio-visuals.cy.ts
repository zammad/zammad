// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `pnpm cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '#cy/utils.ts'

const radioOptions = [
  { label: 'Incoming Phone', value: 1, icon: 'phone-in' },
  { label: 'Outgoing Phone', value: 2, icon: 'phone-out' },
  { label: 'Send Email', value: 3, icon: 'mail-out' },
]

describe('testing visuals for "FieldRadio"', () => {
  it('renders as buttons', () => {
    mountFormField('radio', {
      buttons: true,
      options: radioOptions,
    })
    checkFormMatchesSnapshot()
    cy.findByText('Incoming Phone')
      .click()
      .then(() => {
        checkFormMatchesSnapshot({ subTitle: 'checked' })
      })
  })

  it('renders as disabled buttons', () => {
    mountFormField('radio', {
      buttons: true,
      disabled: true,
      options: radioOptions,
    })
    checkFormMatchesSnapshot()
  })

  it(`renders hidden radio`, () => {
    mountFormField('radio', { label: 'Radio', labelSrOnly: true })
    checkFormMatchesSnapshot()
  })
})
