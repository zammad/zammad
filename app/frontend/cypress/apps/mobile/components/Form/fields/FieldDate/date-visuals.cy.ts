// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `pnpm cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { mountFormField, checkFormMatchesSnapshot } from '#cy/utils.ts'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'

describe('testing visuals for "FieldDate"', () => {
  const inputs = [
    { type: 'date', value: '2021-01-01' },
    { type: 'datetime', value: '2021-01-01T13:12:00Z' },
  ]

  inputs.forEach(({ type, value }) => {
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
        .click()
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'open', type })
        })
    })

    it(`renders filled ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        maxDate: '2021-01-31',
        value,
      })
      checkFormMatchesSnapshot({ type })
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
    })

    it(`renders invalid ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        required: true,
        maxDate: '2021-01-31',
        validationVisibility: FormValidationVisibility.Live,
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders linked ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        link: '/',
        maxDate: '2021-01-31',
        value,
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders disabled ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        disabled: true,
        maxDate: '2021-01-31',
      })
      checkFormMatchesSnapshot({ type })
    })

    it(`renders hidden ${type}`, () => {
      mountFormField(type, { id: 'datetime', label: type, labelSrOnly: true, value })
      checkFormMatchesSnapshot({ type })
    })
  })
})
