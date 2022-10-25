// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

import './hide-scroll.css'

const longText =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar. Quisque placerat nibh et dignissim tincidunt. Morbi semper tortor at dolor mollis laoreet. Aenean fringilla fermentum leo non finibus. Nulla porttitor lacus diam, at vestibulum risus viverra a'

describe('testing visuals for "FieldTextarea"', () => {
  it('renders basic textarea', () => {
    mountFormField('textarea', { label: 'textarea' })
    checkFormMatchesSnapshot('basic')
    cy.get('textarea')
      .click()
      .then(() => {
        checkFormMatchesSnapshot('basic - focused')
      })

    cy.get('textarea')
      .type('Some Text')
      .then(() => {
        checkFormMatchesSnapshot('basic - filled')
      })
  })

  it(`renders required textarea`, () => {
    mountFormField('textarea', { label: 'textarea', required: true })
    checkFormMatchesSnapshot('required')
    cy.get('textarea')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot('required - focused')
      })
    cy.get('textarea')
      .type('Some Text')
      .then(() => {
        checkFormMatchesSnapshot('required - filled')
      })
  })

  it('renders invalid textarea', () => {
    mountFormField('textarea', {
      label: 'textarea',
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })
    checkFormMatchesSnapshot('required - invalid')
  })

  it(`renders disabled textarea`, () => {
    mountFormField('textarea', { label: 'textarea', disabled: true })
    checkFormMatchesSnapshot('disabled')
  })

  it('scrolled textarea has correct label', () => {
    mountFormField('textarea', { label: 'textarea', value: longText })
    checkFormMatchesSnapshot('scrolled')
    cy.get('textarea')
      .scrollTo('bottom')
      .then(() => {
        checkFormMatchesSnapshot('scrolled - bottom')
      })
  })
})
