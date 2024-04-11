// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `pnpm cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '#cy/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

import './hide-scroll.css'

const longText =
  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec vestibulum sem quis purus elementum pulvinar. Quisque placerat nibh et dignissim tincidunt. Morbi semper tortor at dolor mollis laoreet. Aenean fringilla fermentum leo non finibus. Nulla porttitor lacus diam, at vestibulum risus viverra a'

describe('testing visuals for "FieldTextarea"', () => {
  it('renders basic textarea', () => {
    mountFormField('textarea', { label: 'textarea' })
    checkFormMatchesSnapshot()
    cy.get('textarea')
      .click()
      .then(() => {
        checkFormMatchesSnapshot()
      })

    cy.get('textarea')
      .type('Some Text')
      .then(() => {
        checkFormMatchesSnapshot()
      })
  })

  it(`renders required textarea`, () => {
    mountFormField('textarea', { label: 'textarea', required: true })
    checkFormMatchesSnapshot()
    cy.get('textarea')
      .focus()
      .then(() => {
        checkFormMatchesSnapshot()
      })
    cy.get('textarea')
      .type('Some Text')
      .then(() => {
        checkFormMatchesSnapshot()
      })
  })

  it('renders invalid textarea', () => {
    mountFormField('textarea', {
      label: 'textarea',
      required: true,
      validationVisibility: FormValidationVisibility.Live,
    })
    checkFormMatchesSnapshot()
  })

  it('renders textarea with help', () => {
    mountFormField('textarea', {
      label: 'textarea',
      help: 'Help Message!',
    })
    checkFormMatchesSnapshot()
  })

  it(`renders disabled textarea`, () => {
    mountFormField('textarea', { label: 'textarea', disabled: true })
    checkFormMatchesSnapshot()
  })

  it('scrolled textarea has correct label', () => {
    mountFormField('textarea', { label: 'textarea', value: longText })
    checkFormMatchesSnapshot()
    cy.get('textarea')
      .scrollTo('bottom')
      .then(() => {
        checkFormMatchesSnapshot()
      })
  })

  it(`renders hidden textarea`, () => {
    mountFormField('textarea', { label: 'textarea', labelSrOnly: true })
    checkFormMatchesSnapshot()
    cy.get('textarea')
      .type('Some text')
      .then(() => {
        checkFormMatchesSnapshot({ subTitle: 'filled' })
      })
  })
})
