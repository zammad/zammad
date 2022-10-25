// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { CheckboxVariant } from '@shared/components/Form/fields/FieldCheckbox/types'
import { FormValidationVisibility } from '@shared/components/Form/types'

describe('testing visuals for "FieldCheckbox"', () => {
  describe('basic checkbox', () => {
    it('renders default basic checkbox', () => {
      mountFormField('checkbox', { label: 'Checkbox' })
      cy.get('.formkit-outer').then(($el) => {
        $el.css('min-height', '24px')
        checkFormMatchesSnapshot('default - unchecked')
        cy.findByLabelText('Checkbox')
          .check()
          .then(() => {
            checkFormMatchesSnapshot('default - checked')
          })
      })
    })

    it('renders default required checkbox', () => {
      mountFormField('checkbox', { label: 'Checkbox', required: true })
      cy.get('.formkit-outer').then(($el) => {
        $el.css('min-height', '24px')
        checkFormMatchesSnapshot('default - required')
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
        checkFormMatchesSnapshot('default - invalid')
      })
    })

    it('renders default disabled checkbox', () => {
      mountFormField('checkbox', { label: 'Checkbox', disabled: true })
      cy.get('.formkit-outer').then(($el) => {
        $el.css('min-height', '24px')
        checkFormMatchesSnapshot('default - disabled')
      })
    })
  })

  describe('switch checkbox', () => {
    it('renders switch basic checkbox', () => {
      mountFormField('checkbox', {
        label: 'Checkbox',
        variant: CheckboxVariant.Switch,
      })
      checkFormMatchesSnapshot('switch - unchecked')
      cy.findByLabelText('Checkbox')
        .check({ force: true })
        .then(() => {
          checkFormMatchesSnapshot('switch - checked')
        })
    })

    it('renders switch required checkbox', () => {
      mountFormField('checkbox', {
        label: 'Checkbox',
        variant: CheckboxVariant.Switch,
        required: true,
      })
      checkFormMatchesSnapshot('switch - required')
    })

    it('renders switch invalid checkbox', () => {
      mountFormField('checkbox', {
        label: 'Checkbox',
        variant: CheckboxVariant.Switch,
        required: true,
        validationVisibility: FormValidationVisibility.Live,
      })
      checkFormMatchesSnapshot('switch - invalid')
    })

    it('renders switch disabled checkbox', () => {
      mountFormField('checkbox', {
        label: 'Checkbox',
        disabled: true,
        variant: CheckboxVariant.Switch,
      })
      checkFormMatchesSnapshot('switch - disabled')
    })
  })
})
