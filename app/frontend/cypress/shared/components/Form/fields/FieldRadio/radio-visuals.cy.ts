// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'

const radioOptions = [
  { label: 'Incoming Phone', value: 1, icon: 'mobile-phone-in' },
  { label: 'Outgoing Phone', value: 2, icon: 'mobile-phone-out' },
  { label: 'Send Email', value: 3, icon: 'mobile-mail-out' },
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
})
