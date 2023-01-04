// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { checkFormMatchesSnapshot, mountFormField } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

const variants = {
  true: 'Yes',
  false: 'No',
}

describe('testing visuals for "FieldToggle"', () => {
  it('renders basic toggle', () => {
    mountFormField('toggle', { label: 'Toggle', variants, value: false })
    checkFormMatchesSnapshot()
    cy.get('[tabindex="0"]')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot({ subTitle: 'focused' })
      })
  })

  it('renders checked toggle', () => {
    mountFormField('toggle', { label: 'Toggle', variants, value: true })
    checkFormMatchesSnapshot()
  })

  it('renders disabled toggle', () => {
    mountFormField('toggle', { label: 'Toggle', variants, disabled: true })
    checkFormMatchesSnapshot()
  })

  it('renders invalid toggle', () => {
    mountFormField('toggle', {
      label: 'Toggle',
      required: true,
      variants,
      validationVisibility: FormValidationVisibility.Live,
    })
    checkFormMatchesSnapshot()
  })

  it('renders required toggle', () => {
    mountFormField('toggle', { label: 'Toggle', variants, required: true })
    checkFormMatchesSnapshot()
  })
})
