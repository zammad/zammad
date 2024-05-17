// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '#cy/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

describe('testing visuals for "FieldDate"', () => {
  const inputs = [
    { type: 'date', input: '2021-01-01' },
    { type: 'datetime', input: '2021-01-01 13:12' },
  ]

  inputs.forEach(({ type, input }) => {
    it(`renders basic ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        maxDate: '2021-01-31',
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

    it(`renders help for ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        maxDate: '2021-01-31',
        help: 'Help message!',
      })
      cy.findByLabelText('Date').then(() => {
        checkFormMatchesSnapshot({ subTitle: 'help', type })
      })
    })

    it(`renders required ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        required: true,
        maxDate: '2021-01-31',
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
        id: 'datetime',
        label: 'Date',
        required: true,
        maxDate: '2021-01-31',
        validationVisibility: FormValidationVisibility.Live,
      })
      checkFormMatchesSnapshot({ type })
    })

    it('renders linked', () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        link: '/',
        maxDate: '2021-01-31',
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

    it('renders disabled', () => {
      mountFormField('date', {
        id: 'datetime',
        label: 'Date',
        disabled: true,
        maxDate: '2021-01-31',
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders hidden ${type}`, () => {
      mountFormField(type, { id: 'datetime', label: type, labelSrOnly: true })
      checkFormMatchesSnapshot({ type })
      cy.findByLabelText(type)
        .type(`${input}{enter}`)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })
  })
})
