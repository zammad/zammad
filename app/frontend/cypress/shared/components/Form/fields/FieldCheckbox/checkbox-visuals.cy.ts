// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

describe('testing visuals for "FieldCheckbox"', () => {
  describe('basic checkbox', () => {
    it('renders default basic checkbox', () => {
      mountFormField('checkbox', { label: 'Checkbox' })
      cy.get('.formkit-outer').then(($el) => {
        $el.css('min-height', '24px')
        checkFormMatchesSnapshot({ subTitle: 'unchecked' })
        cy.findByLabelText('Checkbox')
          .check()
          .then(() => {
            checkFormMatchesSnapshot({ subTitle: 'checked' })
          })
      })
    })

    it('renders default required checkbox', () => {
      mountFormField('checkbox', { label: 'Checkbox', required: true })
      cy.get('.formkit-outer').then(($el) => {
        $el.css('min-height', '24px')
        checkFormMatchesSnapshot()
      })
    })

    it('renders default invalid checkbox', () => {
      mountFormField('checkbox', {
        label: 'Checkbox',
        required: true,
        validationVisibility: FormValidationVisibility.Live,
      })
      cy.get('.formkit-outer').then(($el) => {
        $el.css('min-height', '24px')
        checkFormMatchesSnapshot()
      })
    })

    it('renders default disabled checkbox', () => {
      mountFormField('checkbox', { label: 'Checkbox', disabled: true })
      cy.get('.formkit-outer').then(($el) => {
        $el.css('min-height', '24px')
        checkFormMatchesSnapshot()
      })
    })
  })
})
