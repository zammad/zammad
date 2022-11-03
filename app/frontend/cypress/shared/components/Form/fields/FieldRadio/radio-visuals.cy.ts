// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'

const radioOptions = [
  { label: 'Incoming Phone', value: 1, icon: 'received-calls' },
  { label: 'Outgoing Phone', value: 2, icon: 'outbound-calls' },
  { label: 'Send Email', value: 3, icon: 'email' },
]

describe('testing visuals for "FieldRadio"', () => {
  it('renders as buttons', () => {
    mountFormField('radio', {
      buttons: true,
      options: radioOptions,
    })
    checkFormMatchesSnapshot('basic')
    cy.findByText('Incoming Phone')
      .click()
      .then(() => {
        checkFormMatchesSnapshot('basic - checked')
      })
  })

  it('renders as disabled buttons', () => {
    mountFormField('radio', {
      buttons: true,
      disabled: true,
      options: radioOptions,
    })
    checkFormMatchesSnapshot('disabled')
  })
})
