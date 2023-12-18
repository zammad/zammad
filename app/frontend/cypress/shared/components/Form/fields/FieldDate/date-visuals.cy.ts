// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

// To update snapshots, run `yarn cypress:snapshots`
// DO NOT update snapshots, when running with --open flag (Cypress GUI)

import { FormValidationVisibility } from '#shared/components/Form/types.ts'
import { mountFormField, checkFormMatchesSnapshot } from '#cy/utils.ts'

const waitForDateTimeRender = () => {
  cy.get('#datetime').should(($datetime) => {
    expect($datetime).to.have.attr('data-rendered', 'true')
  })
}

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
        maxDate: '2021-02-01',
      })
      waitForDateTimeRender()
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
        maxDate: '2021-02-01',
        help: 'Help message!',
      })
      waitForDateTimeRender()
      cy.findByLabelText('Date').then(() => {
        checkFormMatchesSnapshot({ subTitle: 'help', type })
      })
    })

    it(`renders required ${type}`, () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        required: true,
        maxDate: '2021-02-01',
      })
      waitForDateTimeRender()
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
        maxDate: '2021-02-01',
        validationVisibility: FormValidationVisibility.Live,
      })
      waitForDateTimeRender()
      checkFormMatchesSnapshot({ type })
    })

    it('renders linked', () => {
      mountFormField(type, {
        id: 'datetime',
        label: 'Date',
        link: '/',
        maxDate: '2021-02-01',
      })
      waitForDateTimeRender()
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
        maxDate: '2021-02-01',
      })
      waitForDateTimeRender()
      checkFormMatchesSnapshot({ type })
    })

    it(`renders hidden ${type}`, () => {
      mountFormField(type, { id: 'datetime', label: type, labelSrOnly: true })
      waitForDateTimeRender()
      checkFormMatchesSnapshot({ type })
      cy.findByLabelText(type)
        .type(`${input}{enter}`)
        .then(() => {
          checkFormMatchesSnapshot({ subTitle: 'filled', type })
        })
    })
  })
})
