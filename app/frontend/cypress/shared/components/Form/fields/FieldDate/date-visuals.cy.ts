// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '@cy/utils'
import { FormValidationVisibility } from '@shared/components/Form/types'

describe('testing visuals for "FieldDate"', () => {
  const inputs = [
    { type: 'date', input: '2021-01-01' },
    { type: 'datetime', input: '2021-01-01 13:12' },
  ]

  inputs.forEach(({ type, input }) => {
    it(`renders basic ${type}`, () => {
      mountFormField(type, { label: 'Date', maxDate: '2021-02-01' })
      checkFormMatchesSnapshot({ type })
      cy.findByLabelText('Date')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'focused', type })
        })
      cy.findByLabelText('Date')
        .type(`${input}{enter}`)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })

    it(`renders required ${type}`, () => {
      mountFormField(type, {
        label: 'Date',
        required: true,
        maxDate: '2021-02-01',
      })
      checkFormMatchesSnapshot({ type })
      cy.findByLabelText('Date')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'focused', type })
        })
      cy.findByLabelText('Date')
        .type(`${input}{enter}`)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })

    it('renders invalid', () => {
      mountFormField(type, {
        label: 'Date',
        required: true,
        maxDate: '2021-02-01',
        validationVisibility: FormValidationVisibility.Live,
      })
      checkFormMatchesSnapshot({ type })
    })

    it('renders linked', () => {
      mountFormField(type, { label: 'Date', link: '/', maxDate: '2021-02-01' })
      checkFormMatchesSnapshot({ type })
      cy.findByLabelText('Date')
        .focus()
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'focused', type })
        })
      cy.findByLabelText('Date')
        .type(`${input}{enter}`)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })

    it('renders disabled', () => {
      mountFormField('date', {
        label: 'Date',
        disabled: true,
        maxDate: '2021-02-01',
      })
      checkFormMatchesSnapshot({ type })
    })
  })
})
